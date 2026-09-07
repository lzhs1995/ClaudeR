settings <- list(print_to_console = FALSE, log_to_file = FALSE, log_file_path = "")
Sys.setenv(CLAUDER_ASYNC_OUTPUT_MAX_BYTES = "65536")
job_id <- paste0("async-io-test-", Sys.getpid())
payload <- paste(rep("x", 256), collapse = "")
code <- sprintf(
  paste(
    "for (i in seq_len(2000L)) cat(%s, '\\n', file = stderr(), sep = '')",
    "clauder_progress('flood_complete', 'stderr exceeded pipe capacity', 90)",
    "cat('ASYNC_FILE_BACKED_OK\\n')",
    sep = "; "
  ),
  encodeString(payload, quote = '"')
)

started <- ClaudeR:::start_background_job(code, job_id, settings = settings)
stopifnot(isTRUE(started$success), identical(started$job_id, job_id))

deadline <- Sys.time() + 30
repeat {
  result <- ClaudeR:::check_background_job(job_id)
  if (identical(result$status, "complete")) break
  if (Sys.time() > deadline) stop("file-backed async job did not complete")
  Sys.sleep(0.05)
}

stopifnot(
  isTRUE(result$success),
  grepl("ASYNC_FILE_BACKED_OK", result$output, fixed = TRUE),
  result$stderr_bytes > 65536,
  isTRUE(result$stderr_truncated),
  nchar(result$stderr, type = "bytes") <= 65536,
  identical(result$progress$stage, "flood_complete")
)

replayed <- ClaudeR:::check_background_job(job_id)
stopifnot(identical(replayed$status, "complete"), identical(replayed$output, result$output))
