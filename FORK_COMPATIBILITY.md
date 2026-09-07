# LZHS compatibility distribution

This repository is a fork of [IMNMV/ClaudeR](https://github.com/IMNMV/ClaudeR),
not the upstream release channel. The original upstream README below remains
available for its general tool documentation.

The workbench compatibility line uses R package `0.14.1.9002` and bridge
`0.14.5.post1`, intended for tag `v0.14.1.9002-lzhs.1`. Install both halves from
the same immutable tag, then install
[clauder-rstudio-workbench](https://github.com/lzhs1995/clauder-rstudio-workbench).
Do not mix this R package with a bare PyPI `uvx clauder-mcp` invocation.

Retained fork capabilities include async stage/message/update-time progress,
file-backed stdout/stderr to prevent pipe backpressure, codebook writer
detection and Copilot CLI setup support. This is not merely a Copilot adapter.

## Discovery reliability changes

- R discovery writes use a per-record lock, private temporary file and atomic
  rename; same-owner refresh preserves the started-at/token identity.
- Read-only process enumeration replaces signal-based probing. Unknown/corrupt
  records are not evidence of process death and are retained.
- A conflicting live/unknown owner blocks registration. A newly started HTTP
  server whose discovery claim fails is rolled back; other servers are untouched.
- Reopening the addin refreshes discovery without restarting its existing server.
- Bridge readers never delete discovery files. Multiple sessions require explicit
  selection; loss/change of a bound identity blocks rather than rerouting code.
- Bridge tools/list remains available when there is no running RStudio session.

Locks intentionally are not automatically reclaimed after a crashed writer;
inspect the exact lock and owning process before removing it. No arbitrary
process is killed to recover discovery. A reused PID cannot authenticate to a
different token, and an explicit reconnect is required after identity changes.

## Verification boundaries

`discovery-reliability` CI runs native PID/discovery and bridge regressions on
Windows, macOS and Linux. Existing R functional checks and bridge tests remain.
CI's R subprocess tests do not certify a GUI RStudio session or an agent's native
tool registry. Verify those separately using workbench's current-agent native
smoke, preserving the original async job ID. Installation on disk does not
change code already loaded in a running R/Python process.

These safeguards address reproducible failure modes; they do not promise that
an external MCP host can never fail or attribute an unknown historical config
write to a particular program.
