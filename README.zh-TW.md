<div align="center">
  <img src="assets/logo.svg" alt="ClaudeR 標誌" width="180"/>
  <h1>ClaudeR：RStudio 與 AI agent 的連接工具</h1>
</div>

[English](README.md) · 繁體中文

ClaudeR 透過 RStudio addin 與 Python MCP bridge，讓具備相容 MCP 介面的 AI agent 執行 R 程式、讀取結果與圖形，並保留可追溯的執行紀錄。研究資料與模型在實際 R 工作階段中處理；分析規格、結果解讀與文稿主張仍須由研究者核驗。

## 本儲存庫與上游的關係

本儲存庫是 [IMNMV/ClaudeR](https://github.com/IMNMV/ClaudeR) 的維護分支，提供與 [clauder-rstudio-workbench](https://github.com/lzhs1995/clauder-rstudio-workbench) 配套的相容版本。英文 README 保留上游的功能說明、安裝方式及歷史更新；使用本維護分支時，先讀 [FORK_COMPATIBILITY.md](FORK_COMPATIBILITY.md)，依配套版本安裝。

目前候選配套為 ClaudeR R 套件 `0.16.6.9001`、MCP bridge `0.16.6.post1` 與 workbench `0.7.0`。來源納入上游開發提交 `3b56327527919b307b5466c3647ecb004e27775f`，並保留維護分支的相容性修補。R 套件與 bridge 使用 workbench 的 `runtime-compatibility.json` 所固定的同一來源及關鍵檔案 SHA。完整發布驗收仍在進行。

此分支保留非同步工作的階段／訊息／更新時間、檔案式標準輸出與錯誤輸出、codebook 寫入者偵測及 Copilot CLI 設定支援。會話探索使用非破壞式程序檢查與原子寫入；已綁定會話消失或身分改變時，停止向該目標派送，保留原工作與紀錄。

## 可用工作

| 工作 | 入口與結果 |
|---|---|
| 在 RStudio 執行 R | MCP 執行工具回傳程式輸出；繪圖使用相應圖形工具 |
| 追蹤長時間工作 | `execute_r_async` 建立工作；以原 `job_id` 呼叫 `get_async_result`，`wait_s=0` 可立即讀取狀態 |
| 終端 R 與協作消息 | `start_server()`／`stop_server()` 管理終端服務；`wake_on_message` 提供支援客戶端可監看完成的背景命令 |
| 保存研究過程 | 執行日誌、工作階段檢查點、腳本與分析產物 |
| 協作與文稿核對 | 協作提示、數值／引文核對及文稿審查工具；依實際功能及證據判定成果 |

完整功能與 R 函式範例見[英文 README](README.md)。具備多個 agent 對話不代表可以同時修改同一個 R 物件；共用會話的寫入須協調，獨立工作應使用明確隔離的工作階段或 worker。

## 安裝配套版本

先準備 Git、R、RStudio、Python 3.14、uv 與所需 R 相依套件。取得同一候選交付的 workbench `0.7.0` 固定來源，以及其 `runtime-compatibility.json` 指定的 ClaudeR 來源。在 workbench 根目錄閱讀 `docs/UPGRADE_0.7.0.zh-TW.md`，依 `paired_release stage`、`verify` 流程建立隔離配對。兩個來源目錄及 manifest 的身分會寫入安裝回執。

以下命令先顯示配套安裝與核驗參數。實際 `stage` 須指定交付來源、獨立版本目錄與本機 Python／R／Rscript 絕對路徑，並先核對預覽。

### macOS／Linux

```bash
export PYTHONPATH="$PWD/skills/clauder-rstudio-workbench"
python3.14 -m clauder_workbench.paired_release stage --help
python3.14 -m clauder_workbench.paired_release verify --help
```

`stage` 預設產生計畫，加 `--apply` 才建立版本目錄。`verify` 會實際載入並核對 R 與 bridge。需要 RStudio 功能時，目標使用者仍須有可用的 RStudio／addin 工作階段。

### Windows

在 workbench 根目錄使用相同模組。下例以 Python Launcher 選擇已安裝的 Python 3.14。正式執行時依升級指南指定真正的 `python.exe`、`R.exe` 和 `Rscript.exe`。

```powershell
$env:PYTHONPATH = Join-Path (Get-Location) 'skills/clauder-rstudio-workbench'
py -3.14 -m clauder_workbench.paired_release stage --help
py -3.14 -m clauder_workbench.paired_release verify --help
```

成功的 `verify` 回執會提供該配對的 client command 與 R library。接著依使用中的客戶端設定入口，並核驗其實際載入與原生呼叫。候選來源、隔離安裝及客戶端接續步驟由配套指南維護。[Workbench 專案](https://github.com/lzhs1995/clauder-rstudio-workbench)

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

本候選已在 macOS 與 Windows 隔離安裝並載入 R `0.16.6.9001` 和 bridge `0.16.6.post1`。兩端獨立 MCP 客戶端均實際列出 42 個工具，包含 `wake_on_message` 與 `get_async_result` 的 `wait_s` 參數。正式發布、固定公開版本回下載、現役客戶端載入及完整研究流程驗收仍在進行。

以下是歷史固定提交 [a61aac7a](https://github.com/lzhs1995/ClaudeR/commit/a61aac7ae40e2c8533f9469bba6e610e2dda3f02) 的 GitHub 紀錄。

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
