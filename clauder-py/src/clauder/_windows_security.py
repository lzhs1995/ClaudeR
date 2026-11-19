"""Create token-bearing discovery files with a private Windows DACL.

The DACL is supplied at CREATE_NEW, before any token bytes exist, and read
back through the open handle. No chmod/POSIX-mode claim is made on Windows.
Administrators with ownership/debug privileges remain outside this guarantee.
"""
from __future__ import annotations

import ctypes
from ctypes import wintypes
import os
import secrets


def private_temp(directory):
    import msvcrt

    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    security = ctypes.WinDLL("advapi32", use_last_error=True)
    pointer = ctypes.c_void_p
    kernel.GetCurrentProcess.restype = wintypes.HANDLE
    kernel.CloseHandle.argtypes = [wintypes.HANDLE]
    kernel.CloseHandle.restype = wintypes.BOOL
    kernel.LocalFree.argtypes = [pointer]
    kernel.LocalFree.restype = pointer
    security.OpenProcessToken.argtypes = [wintypes.HANDLE, wintypes.DWORD,
                                          ctypes.POINTER(wintypes.HANDLE)]
    security.OpenProcessToken.restype = wintypes.BOOL
    security.GetTokenInformation.argtypes = [wintypes.HANDLE, ctypes.c_int,
                                             pointer, wintypes.DWORD,
                                             ctypes.POINTER(wintypes.DWORD)]
    security.GetTokenInformation.restype = wintypes.BOOL
    security.ConvertSidToStringSidW.argtypes = [pointer, ctypes.POINTER(wintypes.LPWSTR)]
    security.ConvertSidToStringSidW.restype = wintypes.BOOL
    security.ConvertStringSecurityDescriptorToSecurityDescriptorW.argtypes = [
        wintypes.LPCWSTR, wintypes.DWORD, ctypes.POINTER(pointer),
        ctypes.POINTER(wintypes.DWORD)]
    security.ConvertStringSecurityDescriptorToSecurityDescriptorW.restype = wintypes.BOOL
    security.GetSecurityInfo.argtypes = [wintypes.HANDLE, ctypes.c_int,
        wintypes.DWORD, pointer, pointer, ctypes.POINTER(pointer), pointer,
        ctypes.POINTER(pointer)]
    security.GetSecurityInfo.restype = wintypes.DWORD
    security.GetSecurityDescriptorControl.argtypes = [pointer,
        ctypes.POINTER(wintypes.WORD), ctypes.POINTER(wintypes.DWORD)]
    security.GetSecurityDescriptorControl.restype = wintypes.BOOL
    security.GetAce.argtypes = [pointer, wintypes.DWORD, ctypes.POINTER(pointer)]
    security.GetAce.restype = wintypes.BOOL

    class Attributes(ctypes.Structure):
        _fields_ = [("length", wintypes.DWORD), ("descriptor", pointer),
                    ("inherit_handle", wintypes.BOOL)]

    class TokenUser(ctypes.Structure):
        _fields_ = [("sid", pointer), ("attributes", wintypes.DWORD)]

    class ACL(ctypes.Structure):
        _fields_ = [("revision", wintypes.BYTE), ("reserved", wintypes.BYTE),
                    ("size", wintypes.WORD), ("count", wintypes.WORD),
                    ("reserved2", wintypes.WORD)]

    kernel.CreateFileW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD,
        wintypes.DWORD, ctypes.POINTER(Attributes), wintypes.DWORD,
        wintypes.DWORD, wintypes.HANDLE]
    kernel.CreateFileW.restype = wintypes.HANDLE

    def sid_text(sid):
        text = wintypes.LPWSTR()
        if not security.ConvertSidToStringSidW(sid, ctypes.byref(text)):
            raise ctypes.WinError(ctypes.get_last_error())
        try:
            return text.value
        finally:
            kernel.LocalFree(ctypes.cast(text, pointer))

    token = wintypes.HANDLE()
    if not security.OpenProcessToken(kernel.GetCurrentProcess(), 0x0008,
                                      ctypes.byref(token)):  # TOKEN_QUERY
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        size = wintypes.DWORD()
        security.GetTokenInformation(token, 1, None, 0, ctypes.byref(size))
        if ctypes.get_last_error() != 122 or size.value == 0:
            raise ctypes.WinError(ctypes.get_last_error())
        buffer = ctypes.create_string_buffer(size.value)
        if not security.GetTokenInformation(token, 1, buffer, size,
                                             ctypes.byref(size)):
            raise ctypes.WinError(ctypes.get_last_error())
        user = sid_text(ctypes.cast(buffer, ctypes.POINTER(TokenUser)).contents.sid)
    finally:
        kernel.CloseHandle(token)

    descriptor = pointer()
    if not security.ConvertStringSecurityDescriptorToSecurityDescriptorW(
            "D:P(A;;FA;;;" + user + ")", 1, ctypes.byref(descriptor), None):
        raise ctypes.WinError(ctypes.get_last_error())
    attributes = Attributes(ctypes.sizeof(Attributes), descriptor, False)
    handle = None
    path = None
    created = False
    try:
        for _ in range(10):
            path = os.path.join(directory, ".discovery-" + secrets.token_hex(16))
            # Generic write plus READ_CONTROL for independent DACL readback;
            # no sharing while the token file is being populated.
            handle = kernel.CreateFileW(path, 0x40020000, 0,
                                         ctypes.byref(attributes), 1, 0x80, None)
            if handle != ctypes.c_void_p(-1).value:
                created = True
                break
            handle = None
            error = ctypes.get_last_error()
            if error not in (80, 183):
                raise ctypes.WinError(error)
        if handle is None:
            raise FileExistsError("Could not create a unique discovery file")
        read_descriptor, dacl = pointer(), pointer()
        error = security.GetSecurityInfo(handle, 1, 4, None, None,
            ctypes.byref(dacl), None, ctypes.byref(read_descriptor))
        if error:
            raise ctypes.WinError(error)
        try:
            control, revision = wintypes.WORD(), wintypes.DWORD()
            if not security.GetSecurityDescriptorControl(read_descriptor,
                    ctypes.byref(control), ctypes.byref(revision)):
                raise ctypes.WinError(ctypes.get_last_error())
            if not control.value & 0x1000 or not dacl.value:
                raise PermissionError("Discovery file has no protected DACL")
            if ctypes.cast(dacl, ctypes.POINTER(ACL)).contents.count != 1:
                raise PermissionError("Discovery file has unexpected access entries")
            ace = pointer()
            if not security.GetAce(dacl, 0, ctypes.byref(ace)):
                raise ctypes.WinError(ctypes.get_last_error())
            ace_type = ctypes.c_ubyte.from_address(ace.value).value
            ace_flags = ctypes.c_ubyte.from_address(ace.value + 1).value
            rights = wintypes.DWORD.from_address(ace.value + 4).value
            if (ace_type != 0 or ace_flags != 0 or rights != 0x1F01FF
                    or sid_text(ace.value + 8) != user):
                raise PermissionError("Discovery file is not private to the current user")
        finally:
            kernel.LocalFree(read_descriptor)
        fd = msvcrt.open_osfhandle(handle, os.O_WRONLY | os.O_BINARY)
        handle = None  # descriptor owns the handle now
        return fd, path
    except Exception:
        if handle is not None:
            kernel.CloseHandle(handle)
            handle = None
        if created and path and os.path.exists(path):
            os.unlink(path)  # empty owned file; no token was written
        raise
    finally:
        kernel.LocalFree(descriptor)
