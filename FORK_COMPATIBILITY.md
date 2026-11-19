# LZHS compatibility distribution

This repository is a fork of [IMNMV/ClaudeR](https://github.com/IMNMV/ClaudeR),
not the upstream release channel. The original upstream README below remains
available for its general tool documentation.

The workbench `0.7.0` candidate uses R package `0.16.6.9001` and bridge
`0.16.6.post1` based on full upstream commit
`3b56327527919b307b5466c3647ecb004e27775f`. Use the exact ClaudeR source
commit and critical-file hashes selected in the matching workbench's
`runtime-compatibility.json`. Its `docs/UPGRADE_0.7.0.md` and Traditional
Chinese companion describe isolated `paired_release stage` and `verify`
commands for macOS and Windows. Stage defaults to a plan and creates the
pair only with `--apply`. [Workbench repository](https://github.com/lzhs1995/clauder-rstudio-workbench)

The candidate pair has completed isolated installation and loading on macOS
and Windows. Independent MCP clients on both platforms listed 42 tools,
including `wake_on_message` and the `wait_s` parameter of `get_async_result`.
Full release acceptance, fixed public-source download verification, current
client loading and complete research-pipeline verification remain in progress.
Scientific results retain the software versions recorded by their original runs.

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

## Full-upgrade candidate

All upstream features are retained, including the Python companion, Positron,
annotation batching, async wait, coordination, clean-script export, checkpoint
restore, RNG-preserving output naming and plot device cleanup. One deliberate
policy difference remains: a changed same-name session identity requires an
explicit `connect_session` after inspection; it never silently rebinds code.
Candidate tests and installation are isolated from existing research sessions.
