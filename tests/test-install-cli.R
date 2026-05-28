library(ClaudeR)

capture_install_cli <- function(...) {
  paste(capture.output(suppressMessages(ClaudeR::install_cli(...))), collapse = "\n")
}

output <- capture_install_cli(tools = c("copilot", "qwen"))

stopifnot(grepl("GitHub Copilot CLI", output, fixed = TRUE))
stopifnot(grepl("copilot mcp add r-studio --transport stdio --tools", output, fixed = TRUE))
stopifnot(grepl("~/.copilot/mcp-config.json", output, fixed = TRUE))
stopifnot(grepl('"type": "local"', output, fixed = TRUE))

stopifnot(grepl("Qwen Code CLI", output, fixed = TRUE))
stopifnot(grepl("qwen mcp add --scope user --transport stdio r-studio", output, fixed = TRUE))
stopifnot(grepl("uvx", output, fixed = TRUE))
stopifnot(grepl("clauder-mcp", output, fixed = TRUE))

git_output <- capture_install_cli(
  tools = c("codex", "copilot"),
  mcp_from = "git",
  mcp_repo = "https://github.com/lzhs1995/ClaudeR.git",
  mcp_ref = "v0.2.0-lzhs.1"
)
git_source <- "git+https://github.com/lzhs1995/ClaudeR.git@v0.2.0-lzhs.1#subdirectory=clauder-mcp"
stopifnot(grepl(git_source, git_output, fixed = TRUE))
stopifnot(grepl('args = ["--from", "git+https://github.com/lzhs1995/ClaudeR.git@v0.2.0-lzhs.1#subdirectory=clauder-mcp", "clauder-mcp"]', git_output, fixed = TRUE))

local_root <- file.path(tempdir(), "ClaudeR")
dir.create(file.path(local_root, "clauder-mcp"), recursive = TRUE, showWarnings = FALSE)
writeLines("[project]\nname='clauder-mcp'", file.path(local_root, "clauder-mcp", "pyproject.toml"))
local_output <- capture_install_cli(tools = "codex", mcp_from = "local", mcp_local_path = local_root)
stopifnot(grepl("clauder-mcp", local_output, fixed = TRUE))
stopifnot(grepl('args = ["--from"', local_output, fixed = TRUE))

invalid <- try(ClaudeR::install_cli(tools = "not-a-cli"), silent = TRUE)
stopifnot(inherits(invalid, "try-error"))

invalid_source <- try(ClaudeR::install_cli(tools = "codex", use_uvx = FALSE, mcp_from = "git"), silent = TRUE)
stopifnot(inherits(invalid_source, "try-error"))
