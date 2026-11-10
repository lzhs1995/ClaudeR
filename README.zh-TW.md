<div align="center">
  <img src="assets/logo.svg" alt="ClaudeR 標誌" width="180"/>
  <h1>ClaudeR：RStudio 與 AI agent 的連接工具</h1>
</div>

[English](README.md) · 繁體中文

ClaudeR 透過 RStudio addin 與 Python MCP bridge，讓具備相容 MCP 介面的 AI agent 執行 R 程式、讀取結果與圖形，並保留可追溯的執行紀錄。研究資料與模型在實際 R 工作階段中處理；分析規格、結果解讀與文稿主張仍須由研究者核驗。

## 本儲存庫與上游的關係

本儲存庫是 [IMNMV/ClaudeR](https://github.com/IMNMV/ClaudeR) 的維護分支，提供與 [clauder-rstudio-workbench](https://github.com/lzhs1995/clauder-rstudio-workbench) 配套的相容版本。英文 README 保留上游的功能說明、安裝方式及歷史更新；使用本維護分支時，先讀 [FORK_COMPATIBILITY.md](FORK_COMPATIBILITY.md)，依配套版本安裝。

目前配套為 ClaudeR R 套件 `0.14.1.9002`、MCP bridge `0.14.5.post1`，對應標籤 [v0.14.1.9002-lzhs.1](https://github.com/lzhs1995/ClaudeR/releases/tag/v0.14.1.9002-lzhs.1)。R 套件與 bridge 須來自同一配套來源；不要將此 R 套件與未固定來源的 `uvx clauder-mcp` 混用。

此分支保留非同步工作的階段／訊息／更新時間、檔案式標準輸出與錯誤輸出、codebook 寫入者偵測及 Copilot CLI 設定支援。會話探索使用非破壞式程序檢查與原子寫入；已綁定會話消失或身分改變時，停止向該目標派送，保留原工作與紀錄。

## 可用工作

| 工作 | 入口與結果 |
|---|---|
| 在 RStudio 執行 R | MCP 執行工具回傳程式輸出；繪圖使用相應圖形工具 |
| 追蹤長時間工作 | `execute_r_async` 建立工作；以原 `job_id` 呼叫 `get_async_result` |
| 保存研究過程 | 執行日誌、工作階段檢查點、腳本與分析產物 |
| 協作與文稿核對 | 協作提示、數值／引文核對及文稿審查工具；依實際功能及證據判定成果 |

完整功能與 R 函式範例見[英文 README](README.md)。具備多個 agent 對話不代表可以同時修改同一個 R 物件；共用會話的寫入須協調，獨立工作應使用明確隔離的工作階段或 worker。

## 安裝配套版本

先準備 Git、R、RStudio、Python 與 uv。以下沿用 workbench `v0.6.7` 的已發布安裝入口，安裝 ClaudeR、配套 bridge 與工作流程工具。目的目錄須尚未存在；已有安裝或進行中的研究工作應依其原版本接續。

### macOS／Linux

```bash
git clone --branch v0.14.1.9002-lzhs.1 --single-branch https://github.com/lzhs1995/ClaudeR.git "$HOME/projects/ClaudeR-v0.14.1.9002-lzhs.1"
git clone --branch v0.6.7 --single-branch https://github.com/lzhs1995/clauder-rstudio-workbench.git "$HOME/projects/clauder-rstudio-workbench-v0.6.7"
cd "$HOME/projects/clauder-rstudio-workbench-v0.6.7"
./install.sh --clauder-dir "$HOME/projects/ClaudeR-v0.14.1.9002-lzhs.1" --configure-codex --sync-agents-skill
"$HOME/.local/bin/clauder-workbench" doctor --expect-client codex --check-toml-parse
```

可先在安裝命令末尾加 `--dry-run` 檢查計畫。Claude Code 與 Copilot CLI 分別使用 `--configure-claude`、`--configure-copilot`；只選實際需要設定的客戶端。Linux 仍需可用的 RStudio／addin 工作階段。

### Windows

使用 workbench 的 `install.ps1`，沿用同一配套版本。完整命令、前置條件與選項見 [workbench 繁中安裝說明](https://github.com/lzhs1995/clauder-rstudio-workbench/blob/985694b983f46e049fcaae16b621135fd686d252/README.zh-TW.md)及[英文快速安裝](https://github.com/lzhs1995/clauder-rstudio-workbench/blob/985694b983f46e049fcaae16b621135fd686d252/README.md#quick-start)。

## 讓 agent 連接 RStudio

若尚未啟動 addin，在目標 RStudio 工作階段執行：

```r
library(ClaudeR)
claudeAddin()
```

在 addin 中啟動伺服器，確認所選會話名稱與連接埠。已有健康伺服器或非同步工作時，沿用原會話與工作識別碼；安裝磁碟上的新版本不會自動更新正在執行的 R／Python 程序。

| 客戶端 | 實際入口 | 仍需核驗 |
|---|---|---|
| Codex CLI | workbench 的 Codex 設定選項、持續存在的 `clauder-mcp` 入口 | 當前客戶端能列出並呼叫 `r-studio` 工具 |
| Claude Code | workbench 的 Claude 設定選項 | 目標專案實際載入正確 MCP 設定 |
| GitHub Copilot CLI | workbench 的 Copilot 設定選項 | 當前原生工具介面及所選 RStudio 會話 |
| Gemini CLI、其他 agent | 閱讀配套文件，依客戶端支援的方式設定 MCP | 設定格式、工具發現與真實呼叫須逐一實測 |

可直接交給 agent：

```text
讀取 ClaudeR 的 FORK_COMPATIBILITY.md，以及配套 workbench 的
skills/clauder-rstudio-workbench/SKILL.md。列出可用 RStudio 會話，
綁定我指定的目標，依技能核對同步與非同步呼叫。保留現有研究物件
及工作；沿原 job_id 查詢進度，不因暫時斷線重送長工作。
```

更多入口見 [workbench Agent 快速入門](https://github.com/lzhs1995/clauder-rstudio-workbench/blob/985694b983f46e049fcaae16b621135fd686d252/docs/agent-quickstart.md)。本儲存庫的 [llms-install.md](llms-install.md) 保留上游自動安裝指引；本分支仍以配套版本說明為準。

## 已驗證範圍與使用界線

以固定提交 [a61aac7a](https://github.com/lzhs1995/ClaudeR/commit/a61aac7ae40e2c8533f9469bba6e610e2dda3f02) 的 GitHub 紀錄為準：

- [Windows／macOS／Ubuntu 的會話探索安全回歸](https://github.com/lzhs1995/ClaudeR/actions/runs/34123530374)均成功。
- [R CMD check、R 解析與功能檢查、MCP bridge 建置及 stdio 握手](https://github.com/lzhs1995/ClaudeR/actions/runs/34123530376)均成功。
- 這些是該提交的 CI 紀錄；本頁文檔更新沒有重新執行 R 分析或新增原生客戶端驗收。

`doctor`、HTTP 回應、獨立 stdio 握手、執行中客戶端的原生 MCP 呼叫須分別記錄。正式工作應取得當前客戶端實際的 `list_sessions → execute_r → execute_r_async → get_async_result` 證據，並保留原非同步工作識別碼。現有 CI 不等於所有 agent、GUI RStudio 工作階段或完整研究任務均已驗證。

ClaudeR 能以目前使用者權限執行 R、讀寫檔案與連接網路，程式檢查不是隔離沙箱。保存執行日誌，明確綁定資料與輸出目錄；公開程式與合成範例可共享，真實憑證、研究資料及私人執行紀錄保留於適當的本機或受控儲存。工具執行成功不代替研究設計、統計假設或文稿內容的實質判斷。

## 延伸閱讀

- [英文功能與操作指南](README.md)
- [維護分支版本與驗證界線](FORK_COMPATIBILITY.md)
- [ClaudeR RStudio Workbench](https://github.com/lzhs1995/clauder-rstudio-workbench)
- [MIT 授權](LICENSE)
