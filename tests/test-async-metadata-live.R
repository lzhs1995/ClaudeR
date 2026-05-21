library(ClaudeR)

settings <- list(
  print_to_console = FALSE,
  log_to_file = FALSE,
  log_file_path = ""
)

job_id <- paste0("metadata_probe_", as.integer(Sys.time()))
code <- paste(
  c(
    "clauder_progress('metadata_start', 'metadata probe started')",
    "Sys.sleep(2)",
    "async_metadata_probe <- list(ok = TRUE, pid = Sys.getpid())",
    "clauder_progress('metadata_complete', 'metadata probe completed')",
    "async_metadata_probe"
  ),
  collapse = "\n"
)

started <- ClaudeR:::start_background_job(
  code,
  job_id = job_id,
  settings = settings,
  agent_id = "codex-validation",
  output_names = "async_metadata_probe"
)

stopifnot(isTRUE(started$success))
stopifnot(identical(started$metadata$job_id, job_id))
stopifnot(identical(started$metadata$agent_id, "codex-validation"))
stopifnot(isTRUE(started$metadata$main_session_available))
stopifnot(identical(started$metadata$output_names, "async_metadata_probe"))
stopifnot(grepl(
  "Lightweight read-only",
  started$parallel_guidance$safe_parallel_work,
  fixed = TRUE
))

Sys.sleep(1)
running <- ClaudeR:::check_background_job(job_id)
stopifnot(identical(running$status, "running"))
stopifnot(identical(running$metadata$job_id, job_id))
stopifnot(identical(running$metadata$output_names, "async_metadata_probe"))

Sys.sleep(3)
completed <- ClaudeR:::check_background_job(job_id)
stopifnot(identical(completed$status, "complete"))
stopifnot(isTRUE(completed$success))
stopifnot(exists("async_metadata_probe", envir = .GlobalEnv, inherits = FALSE))
stopifnot(identical(completed$metadata$output_names, "async_metadata_probe"))
stopifnot(grepl(
  "assigned into the main session",
  completed$output_object_note,
  fixed = TRUE
))

cat("source_async_metadata_probe_ok\n")
cat("job_id=", job_id, "\n", sep = "")
cat("final_stage=", completed$progress$stage, "\n", sep = "")
