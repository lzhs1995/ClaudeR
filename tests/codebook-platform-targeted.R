args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) <= 1L)
# R CMD check 不提供源码路径；直接验证它刚安装的包。
if (length(args) == 1L) {
  root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
  env <- new.env(parent = globalenv())
  source(file.path(root, "R", "codebook.R"), local = env)
} else {
  env <- asNamespace("ClaudeR")
}
# 保留原始跨平台样例；包测试不依赖构建时排除的 .github 目录。
set.seed(13)
proj <- tempfile("proj"); dir.create(proj)
utils::write.csv(data.frame(id = 1:20, v = c(rnorm(18), NA, NA)),
                 file.path(proj, "d.csv"), row.names = FALSE)
writeLines(c("library(jsonlite)",
             paste0("d <- read.csv(", encodeString(normalizePath(file.path(proj, "d.csv"),
                       winslash = "/", mustWork = TRUE), quote = '"'), ")"),
             "saveRDS(d, \"out.rds\")"), file.path(proj, "a.R"))
out <- suppressMessages(env$generate_codebook(proj))
md <- readLines(out)
stopifnot(any(grepl("| v |", md, fixed = TRUE)),
          any(grepl("2 (10.0%)", md, fixed = TRUE)),
          any(grepl("out.rds", md, fixed = TRUE)),
          any(grepl("jsonlite (", md, fixed = TRUE)))
cat("PASS: exact original failed codebook fixture with corrected path quoting\n")
