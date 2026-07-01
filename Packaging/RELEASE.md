# Converse — 打包与发布说明（任务 15）

## 当前构建方式（SPM，开发期）

全程用 Swift Package Manager，CLI 可构建：

```bash
swift build          # debug
swift test           # 全套单测
swift run            # 或 .build/debug/Converse
```

> github.com:443 被墙，已全局配置 `url."git@github.com:".insteadOf "https://github.com/"`，SPM 经 SSH 解析依赖。

## 打包成 .app

```bash
scripts/build-app.sh                  # ad-hoc 签名（仅本机开发验证，Gatekeeper 不放行）
scripts/build-app.sh --sign-dev       # Developer ID + Hardened Runtime + 公证（需凭证）
```

脚本逻辑：
1. `swift build -c release` 产出二进制。
2. 组装 `build/Converse.app/Contents/{MacOS,Resources/bin}`。
3. 拷贝 `tmux` 到 `Resources/bin/tmux`（ISC 许可可捆绑；运行时 App 用绝对路径调起，免用户装 brew）。
4. 写入 `Info.plist`（macOS 13+，developer-tools 分类）。
5. ad-hoc 或 Developer ID + `Converse.entitlements`（Hardened Runtime + `allow-unsigned-executable-memory`/`disable-library-validation` 供 SwiftTerm/tmux，`network.client` 供云端 AI）签名。

## 发布所需外部凭证与服务（PoC 1.3 同源，非技术风险）

以下依赖 Apple/Paddle 账号，属已知成熟路径（iTerm2/Warp 均如此），本地无凭证无法执行：

- **Developer ID 签名 + notarytool 公证 + stapler**：需 Apple Developer 账号（$99/年）。
  ```bash
  CONVERSE_SIGN_IDENTITY="Developer ID Application: <Name>" \
  NOTARY_PROFILE="<notarytool keychain profile>" \
  scripts/build-app.sh --sign-dev
  ```
- **Paddle license 激活**：需 Paddle 账号 → 生成 license key → App 内激活验证（Settings 已存 `ai.api_key_ref`，可扩展 license 校验）。
- **Sparkle 自动更新**：集成 Sparkle 框架 + appcast.xml（后续版本接入）。

## MVP 验收对照（设计文档第七章）

| # | 验收项 | 实现位置 / 状态 |
| - | ------ | --------------- |
| 1 | 新建文件夹/会话并在该目录启动真实 shell | SidebarView + AppState.createSession + TmuxManager.ensureSession ✓ |
| 2 | 会话绑定 tmux，退出后重开可恢复 | TerminalView tmux attach + Task14 syncStatuses/recreate ✓ |
| 3 | 明确命令直接执行，不走 AI | InputBar.submit → InputClassifier.shellCommand → TerminalController.run ✓ |
| 4 | 自然语言 AI 生成命令建议，展示命令+风险，确认后执行 | InputBar → CommandAdvisor.suggest → AiSuggestionCard ✓ |
| 5 | AI 可关闭；关闭后终端能力不受影响 | AppState.aiMode == .off → 提示输入命令；终端/会话/Git 不依赖 AI ✓ |
| 6 | 命令失败可触发 AI 修正（仍需确认） | AiSuggestionCard 失败态 + 报错辅助入口（error_assist）✓ |
| 7 | 普通输出实时显示，长输出可折叠 | SwiftTerm 实时渲染；OutputSummarizer 头尾截断 ✓ |
| 8 | vim/top/less/REPL 进入终端模式 | TerminalController.terminalMode（TUI 命令检测）+ InputBar 禁用 ✓ |
| 9 | sudo 密码不显示/不存储/不发 AI | TerminalController.awaitingPassword 提示；密码走 pty 不入库/不进 AI ✓ |
| 10 | Git 面板只读，无操作按钮 | GitPanel（分支/文件树/diff），无 commit/push 按钮 ✓ |
| 11 | SQLite 存元数据，不存完整大输出 | HistoryService + OutputSummarizer（8KB/200 行）✓ |
| 12 | 历史选中只填入输入框，不直接执行 | CommandPalette 历史 Tab → AppState.fillInput ✓ |
| 13 | 失败仅 重试/编辑后重试/AI 修复，不回滚 | AiSuggestionCard [执行][编辑][取消] ✓ |
| 14 | AI 走 OpenAI-compatible 云端 API，默认 DeepSeek，无本地模型/embedding/向量库 | AiClient + SettingsService 默认值 ✓ |
| 15 | Few-shot 关键词/TF-IDF Top-3 | FewShotStore.retrieve ✓ |

## 安全检查（设计文档要求）

- 真实 API key 仅存 macOS Keychain（`KeychainStore`），SQLite 只存 `api_key_ref`（如 `env:DEEPSEEK_API_KEY`）。
- `Sanitizer` 脱敏管线过滤私钥/API key/token/`.env`/sudo 密码后再进 AI 上下文。
- 输出摘要写库前截断，不存完整大输出。
- 风险检测覆盖 rm -rf / git reset --hard / sudo / dd / 网络脚本 / mkfs 等（RiskDetectorTests）。

## 测试覆盖（swift test，94 项全绿）

- 输入判定（InputClassifierTests）、风险分级含 strict（RiskDetectorTests）、Few-shot 检索（AiTests）、脱敏（AiTests）、输出摘要/历史（OutputAndHistoryTests）、Git porcelain 解析（GitReaderTests）、tmux 解析（TmuxParsingTests）、终端模式（TerminalModeTests）、数据库/Keychain（DatabaseTests）、冒烟（SmokeTests）。
- AI 异常态：AiClientTests 用桩 transport 覆盖 401/429/未配置；AI 故障时终端/会话/Git 路径不受影响（UI 不依赖 AI 返回）。
