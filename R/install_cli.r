#' @title Install and Set Up ClaudeR for CLI Tools
#' @description An installer that configures ClaudeR to be used with command-line
#'   AI tools like the Claude Code CLI, OpenAI Codex CLI, GitHub Copilot CLI,
#'   Qwen Code CLI, and Google Gemini CLI.
#'
#'   By default, it uses `uvx` to run the `clauder-mcp` PyPI package, which
#'   handles all Python dependencies automatically. No Python path or pip
#'   install needed.
#'
#' @param tools A character vector specifying which CLI tools to configure.
#'   Can be `"claude"`, `"codex"`, `"copilot"`, `"qwen"`, `"gemini"`,
#'   or a combination like `c("claude", "codex", "copilot")`.
#' @param use_uvx Logical. If `TRUE` (the default), generates commands using
#'   `uvx clauder-mcp` which handles Python dependencies automatically. If
#'   `FALSE`, falls back to the legacy method of finding a Python executable
#'   and pointing to the bundled script.
#' @param python_path Optional. Only used when `use_uvx = FALSE`. A character
#'   string specifying the absolute path to the Python executable.
#' @param mcp_from Character. Only used when `use_uvx = TRUE`. One of `"pypi"`,
#'   `"git"`, or `"local"`. `"pypi"` preserves the default `uvx clauder-mcp`
#'   behavior. `"git"` runs the MCP bridge from `mcp_repo` at `mcp_ref`.
#'   `"local"` runs the MCP bridge from a local ClaudeR checkout.
#' @param mcp_repo Git repository URL used when `mcp_from = "git"`.
#' @param mcp_ref Git ref, branch, or tag used when `mcp_from = "git"`.
#' @param mcp_local_path Local ClaudeR checkout or `clauder-mcp` directory used
#'   when `mcp_from = "local"`.
#' @param ... Additional arguments passed to `install.packages` for any
#'   missing R dependencies.
#' @details This function will:
#'   1. Check for and install required R packages.
#'   2. Provide you with the exact command to run (for Claude/Codex/Copilot/Qwen)
#'      or the exact JSON to copy (for Gemini/Copilot) to complete the setup.
#' @export
install_cli <- function(tools = "claude",
                        use_uvx = TRUE,
                        python_path = NULL,
                        mcp_from = c("pypi", "git", "local"),
                        mcp_repo = "https://github.com/lzhs1995/ClaudeR.git",
                        mcp_ref = "v0.2.0-lzhs.1",
                        mcp_local_path = NULL,
                        ...) {
  # --- 1. Parameter Validation ---
  cli_choices <- c("claude", "codex", "copilot", "qwen", "gemini")
  tools <- try(match.arg(tools, choices = cli_choices, several.ok = TRUE), silent = TRUE)
  if (inherits(tools, "try-error")) {
    stop("Invalid 'tools' argument. Please choose 'claude', 'codex', 'copilot', 'qwen', 'gemini', or a combination.", call. = FALSE)
  }

  # --- 2. Check R Dependencies ---
  message("--- Step 1: Checking R dependencies ---")
  r_deps <- c("jsonlite", "httpuv", "shiny", "miniUI", "callr")
  missing_r_deps <- r_deps[!sapply(r_deps, requireNamespace, quietly = TRUE)]

  if (length(missing_r_deps) > 0) {
    message(paste("Installing missing R packages:", paste(missing_r_deps, collapse = ", ")))
    utils::install.packages(missing_r_deps, ...)
  } else {
    message("All required R dependencies are already installed.")
  }

  quote_arg <- function(x) {
    shQuote(x, type = if (.Platform$OS.type == "windows") "cmd" else "sh")
  }

  shell_args <- function(args) {
    paste(vapply(args, quote_arg, character(1)), collapse = " ")
  }

  toml_array <- function(args) {
    esc <- gsub("\\\\", "\\\\\\\\", args)
    esc <- gsub('"', '\\"', esc, fixed = TRUE)
    paste0('["', paste(esc, collapse = '", "'), '"]')
  }

  as_json_args <- function(args) {
    as.list(unname(args))
  }

  # --- 3. Resolve the MCP server command ---
  if (use_uvx) {
    mcp_from <- match.arg(mcp_from)
    message("\n--- Step 2: Using uvx (recommended) ---")
    mcp_command <- "uvx"
    if (mcp_from == "pypi") {
      message("The 'clauder-mcp' PyPI package handles all Python dependencies automatically.")
      mcp_args <- "clauder-mcp"
    } else if (mcp_from == "git") {
      if (!nzchar(mcp_repo) || !nzchar(mcp_ref)) {
        stop("'mcp_repo' and 'mcp_ref' must be non-empty when mcp_from = 'git'.", call. = FALSE)
      }
      message(paste("Using clauder-mcp from Git ref:", mcp_ref))
      mcp_args <- c("--from", paste0("git+", mcp_repo, "@", mcp_ref, "#subdirectory=clauder-mcp"), "clauder-mcp")
    } else {
      if (is.null(mcp_local_path) || !nzchar(mcp_local_path)) {
        stop("'mcp_local_path' is required when mcp_from = 'local'.", call. = FALSE)
      }
      local_path <- path.expand(mcp_local_path)
      if (basename(normalizePath(local_path, winslash = "/", mustWork = FALSE)) != "clauder-mcp") {
        local_path <- file.path(local_path, "clauder-mcp")
      }
      if (!file.exists(file.path(local_path, "pyproject.toml"))) {
        stop(paste("Could not find clauder-mcp/pyproject.toml under:", local_path), call. = FALSE)
      }
      message(paste("Using local clauder-mcp source:", local_path))
      mcp_args <- c("--from", normalizePath(local_path, winslash = "\\", mustWork = TRUE), "clauder-mcp")
    }
  } else {
    mcp_from <- match.arg(mcp_from)
    if (mcp_from != "pypi") {
      stop("Set use_uvx = TRUE when using mcp_from = 'git' or mcp_from = 'local'.", call. = FALSE)
    }
    message("\n--- Step 2: Locating Python executable (legacy mode) ---")
    final_python_path <- python_path

    if (is.null(final_python_path)) {
      message("No 'python_path' provided. Searching system PATH...")
      final_python_path <- Sys.which("python3")
      if (final_python_path == "") final_python_path <- Sys.which("python")
      if (final_python_path == "") {
        stop("Could not automatically find a Python executable. Provide the path via 'python_path' or use use_uvx = TRUE.", call. = FALSE)
      }
    } else {
      if (!file.exists(final_python_path)) {
        stop(paste("The provided Python path does not exist:", final_python_path), call. = FALSE)
      }
    }
    message(paste("Using Python executable:", final_python_path))

    # Install Python dependencies
    message("\n--- Step 3: Installing Python dependencies ---")
    message("Attempting to install 'mcp' and 'httpx' using pip...")
    tryCatch({
      system2(final_python_path, args = c("-m", "pip", "install", "--upgrade", "mcp", "httpx"))
      message("Python dependencies installed successfully.")
    }, warning = function(w) {
      message("\nWarning during pip install: ", w$message)
    }, error = function(e) {
      message("\nError during pip install. Please ensure pip is available or install 'mcp' and 'httpx' manually.", call. = FALSE)
    })

    mcp_script_path <- system.file("scripts", "persistent_r_mcp.py", package = "ClaudeR")
    if (mcp_script_path == "") {
      stop("Could not find 'persistent_r_mcp.py'. Please reinstall ClaudeR.", call. = FALSE)
    }

    mcp_command <- final_python_path
    mcp_args <- mcp_script_path
  }

  # --- 4. Generate Final Instructions ---
  step_num <- if (use_uvx) "Step 3" else "Step 4"
  message(paste0("\n--- ", step_num, ": Final Configuration ---"))

  cat("\n====================================================\n")
  cat("ACTION REQUIRED: Please run the following in your terminal.\n")
  cat("====================================================\n")

  for (tool in tools) {
    if (tool == "claude") {
      remove_string <- 'claude mcp remove r-studio -s user 2>/dev/null'
      if (use_uvx) {
        add_string <- paste(
          'claude mcp add --transport stdio --scope user r-studio --',
          quote_arg(mcp_command),
          shell_args(mcp_args)
        )
      } else {
        add_string <- sprintf(
          'claude mcp add --transport stdio --scope user r-studio -- %s %s',
          quote_arg(mcp_command),
          shell_args(mcp_args)
        )
      }
      cat("\n--- For Claude Code CLI ---\n")
      cat("Copy and paste this complete command into your terminal:\n\n")
      cat(remove_string, ";", add_string, "\n\n")
    }

    if (tool == "codex") {
      remove_string <- 'codex mcp remove r-studio 2>/dev/null'
      if (use_uvx) {
        add_string <- paste(
          'codex mcp add r-studio --',
          quote_arg(mcp_command),
          shell_args(mcp_args)
        )
        toml_block <- paste(
          '[mcp_servers.r-studio]',
          'command = "uvx"',
          sprintf('args = %s', toml_array(mcp_args)),
          sep = "\n"
        )
      } else {
        add_string <- sprintf(
          'codex mcp add r-studio -- %s %s',
          quote_arg(mcp_command),
          shell_args(mcp_args)
        )
        toml_block <- paste(
          '[mcp_servers.r-studio]',
          sprintf('command = "%s"', mcp_command),
          sprintf('args = %s', toml_array(mcp_args)),
          sep = "\n"
        )
      }
      cat("\n--- For OpenAI Codex CLI ---\n")
      cat("Pick whichever matches your Codex version:\n\n")
      cat("Option A. Newer Codex (supports `codex mcp add`). Paste this into your terminal:\n\n")
      cat(remove_string, ";", add_string, "\n\n")
      cat("Option B. Older Codex (no `mcp add` subcommand). Open ~/.codex/config.toml\n")
      cat("and add the section below. If an r-studio section already exists, replace it.\n\n")
      cat(toml_block, "\n\n")
    }

    if (tool == "copilot") {
      copilot_env <- list()
      if (.Platform$OS.type == "windows") {
        userprofile <- Sys.getenv("USERPROFILE", unset = "")
        if (nzchar(userprofile)) {
          copilot_env$USERPROFILE <- userprofile
        }
        copilot_env$NO_PROXY <- "127.0.0.1,localhost"
        copilot_env$PYTHONIOENCODING <- "utf-8"
      }

      copilot_env_flags <- character()
      if (length(copilot_env) > 0) {
        copilot_env_flags <- paste(
          "--env",
          vapply(
            names(copilot_env),
            function(name) shQuote(paste0(name, "=", copilot_env[[name]]), type = "cmd"),
            character(1)
          )
        )
      }

      if (use_uvx) {
        add_string <- paste(c(
          "copilot mcp add r-studio --transport stdio --tools \"*\"",
          copilot_env_flags,
          "--",
          quote_arg(mcp_command),
          shell_args(mcp_args)
        ), collapse = " ")
        copilot_server <- list(
          type = "local",
          command = "uvx",
          args = as_json_args(mcp_args)
        )
      } else {
        add_string <- paste(c(
          "copilot mcp add r-studio --transport stdio --tools \"*\"",
          copilot_env_flags,
          "--",
          quote_arg(mcp_command),
          shell_args(mcp_args)
        ), collapse = " ")
        copilot_server <- list(
          type = "local",
          command = mcp_command,
          args = as_json_args(mcp_args)
        )
      }
      if (length(copilot_env) > 0) {
        copilot_server$env <- copilot_env
      }
      copilot_server$tools <- list("*")

      copilot_config <- list(
        mcpServers = list(
          `r-studio` = copilot_server
        )
      )
      copilot_json_string <- jsonlite::toJSON(copilot_config, pretty = TRUE, auto_unbox = TRUE)

      cat("\n--- For GitHub Copilot CLI ---\n")
      cat("Pick whichever setup path you prefer:\n\n")
      cat("Option A. Use the Copilot CLI command:\n\n")
      cat("copilot mcp remove r-studio 2>/dev/null ;", add_string, "\n\n")
      cat("Option B. Open ~/.copilot/mcp-config.json and add or merge this block:\n\n")
      cat(copilot_json_string, "\n\n")
    }

    if (tool == "qwen") {
      remove_string <- 'qwen mcp remove --scope user r-studio 2>/dev/null'
      if (use_uvx) {
        add_string <- paste(
          'qwen mcp add --scope user --transport stdio r-studio',
          quote_arg(mcp_command),
          shell_args(mcp_args)
        )
      } else {
        add_string <- sprintf(
          'qwen mcp add --scope user --transport stdio r-studio %s %s',
          quote_arg(mcp_command),
          shell_args(mcp_args)
        )
      }
      cat("\n--- For Qwen Code CLI ---\n")
      cat("Copy and paste this complete command into your terminal:\n\n")
      cat(remove_string, ";", add_string, "\n\n")
    }

    if (tool == "gemini") {
      if (use_uvx) {
        gemini_config <- list(
          mcpServers = list(
            `r-studio` = list(
              command = "uvx",
              args = as_json_args(mcp_args)
            )
          )
        )
      } else {
        gemini_config <- list(
          mcpServers = list(
            `r-studio` = list(
              command = mcp_command,
              args = as_json_args(mcp_args),
              env = list(PYTHONUNBUFFERED = "1")
            )
          )
        )
      }
      gemini_json_string <- jsonlite::toJSON(gemini_config, pretty = TRUE, auto_unbox = TRUE)
      cat("\n--- For Google Gemini CLI ---\n")
      cat("Edit your Gemini settings file (usually at '~/.gemini/settings.json').\n")
      cat("Add or merge the following 'mcpServers' block into that file:\n\n")
      cat(gemini_json_string, "\n\n")
    }
  }

  cat("====================================================\n")
  cat("Setup is complete after you run the commands above.\n")
  cat("====================================================\n\n")

  invisible()
}
