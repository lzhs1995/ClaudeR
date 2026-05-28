library(ClaudeR)

stopifnot(is.function(ClaudeR:::pid_exists))
stopifnot(isTRUE(ClaudeR:::pid_exists(Sys.getpid())))
stopifnot(identical(ClaudeR:::pid_exists(0), FALSE))
stopifnot(identical(ClaudeR:::pid_exists(NA), FALSE))

cleanup_body <- paste(deparse(body(ClaudeR:::cleanup_stale_discovery_files)), collapse = "\n")
stopifnot(!grepl("tools::pskill", cleanup_body, fixed = TRUE))
stopifnot(grepl("pid_exists", cleanup_body, fixed = TRUE))

progress_path <- tempfile(fileext = ".rds")
progress <- ClaudeR:::write_background_progress(
  progress_path,
  stage = "test_stage",
  message = "test message"
)
stopifnot(identical(progress$stage, "test_stage"))
stopifnot(identical(progress$message, "test message"))
stopifnot(!is.null(progress$updated_at))

read_back <- ClaudeR:::read_background_progress(progress_path)
stopifnot(identical(read_back$stage, "test_stage"))
stopifnot(identical(read_back$message, "test message"))
stopifnot(!is.null(read_back$updated_at))
unlink(progress_path)

guidance <- ClaudeR:::background_parallel_guidance("async_result")
stopifnot(isTRUE(guidance$main_session_available))
stopifnot(grepl("Lightweight read-only", guidance$safe_parallel_work, fixed = TRUE))
stopifnot(grepl("Avoid long synchronous", guidance$avoid_parallel_work, fixed = TRUE))
stopifnot(identical(guidance$output_names, "async_result"))

metadata <- ClaudeR:::background_job_metadata(
  "job_test",
  list(
    agent_id = "agent_test",
    session_name = "default",
    session_port = 8787L,
    started = as.POSIXct("2026-05-21 10:00:00", tz = "UTC"),
    input_names = "x",
    output_names = "async_result"
  )
)
stopifnot(identical(metadata$job_id, "job_test"))
stopifnot(identical(metadata$agent_id, "agent_test"))
stopifnot(identical(metadata$session_name, "default"))
stopifnot(isTRUE(metadata$main_session_available))
stopifnot(identical(metadata$input_names, "x"))
stopifnot(identical(metadata$output_names, "async_result"))

persistent_bridge <- system.file("scripts", "persistent_r_mcp.py", package = "ClaudeR")
stopifnot(file.exists(persistent_bridge))
bridge_text <- paste(readLines(persistent_bridge, warn = FALSE), collapse = "\n")
stopifnot(grepl("Latest progress", bridge_text, fixed = TRUE))
stopifnot(grepl("Final progress", bridge_text, fixed = TRUE))
stopifnot(grepl("Async metadata", bridge_text, fixed = TRUE))
stopifnot(grepl("Parallel guidance", bridge_text, fixed = TRUE))
