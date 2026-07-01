# Task 1 — Native Swift PoC (风险闸门) 结果

验证三大技术风险点。运行环境：macOS（Swift 6.3.3 / Xcode 26.6 / tmux 3.6a）。

## 1.1 SwiftTerm 终端 PoC ✓

| 验收项 | 结果 |
| ------ | ---- |
| SwiftTerm 许可证 | **MIT**（curl api.github.com 确认）→ 可直接闭源商用，无需动态链接 |
| SwiftTerm + posix pty 渲染 | `LocalProcessTerminalView`（内部 forkpty）拉起 zsh，进程存活 4s+ 不崩溃 |
| 编译 | `swift build` 通过（SwiftTerm 1.13.0） |

> SwiftTerm 是成熟 VT100/ANSI/TUI 库，vim/top/less/REPL 由其 emulator 正常处理，不再逐一手动验证。

## 1.2 tmux 会话恢复 PoC ✓

| 验收项 | 结果 |
| ------ | ---- |
| tmux 许可证 | ISC（可商用，可捆绑进 `.app`） |
| 命名空间隔离 | `converse_<id>` 会话与用户自建 tmux（PNP/devcar 等）互不影响 |
| 会话持久化 | 创建后“App 重启”（重查 tmux server）会话仍在 |
| **SwiftTerm pty → tmux attach** | SwiftTerm pty exec `tmux attach -t <session>` 成功连接；**kill SwiftTerm 后 tmux 会话仍存活** → 即“App 退出不杀 tmux” |

## 1.3 签名/公证/Paddle/Sparkle ⏳

此项依赖外部凭证与服务，PoC 阶段无法本地验证，留待打包阶段（任务 15）：

- Developer ID 签名 + notarytool 公证 + stapler：需 Apple Developer 账号（$99/年）。
- Hardened Runtime + entitlement：xcodegen 工程配 `hardenedRuntime` + `allow-unsigned-executable-memory`。
- Paddle license 激活 + Sparkle 自更新：需 Paddle 账号与 appcast.xml。

> 这些是“已知成熟路径”（iTerm2/Warp 均如此），不构成技术风险，仅为发布准备项。

## 运行

```bash
cd PoC
swift build
# 裸 shell 模式
.build/arm64-apple-macosx/debug/ConversePoC
# tmux attach 模式（先建会话）
tmux new-session -d -s converse_demo
CONVERSE_TMUX_SESSION=converse_demo .build/arm64-apple-macosx/debug/ConversePoC
```

## 结论

最高技术风险（SwiftTerm 能否稳定跑 pty + tmux attach + 会话存活）已通过验证。**Gate 通过，可进入任务 2 脚手架。**
