# Converse MVP 开发任务列表

> **版本**: v2.2 · 2026-07-01（按依赖关系重排开发顺序；PoC 前置、风险检测提前、v2.1 细化项融入对应主任务）
> **对应设计文档**: `converse_design_doc_v2.md`（v2.1）
> **技术路线**: Native Swift + SwiftUI + SwiftTerm + posix pty + tmux + GRDB(SQLite) + Keychain（v2.1 由 Electron 改为 macOS 原生）
> **任务组织原则**: 任务编号即开发顺序，后者依赖前者；同一大任务下子任务可并行；标注 `〔v2.1〕` 的项为原型交互细化（设计文档第八章），在所在主任务一并实现。

---

## 设计文档追踪矩阵

| # | 开发任务 | 前置依赖 | 对应设计章节 | 验收来源 |
| - | -------- | -------- | ------------ | -------- |
| 1 | Native Swift PoC | — | [5.1 技术栈](converse_design_doc_v2.md)、[5.6 分发与商业化](converse_design_doc_v2.md) | 风险闸门 |
| 2 | 项目脚手架与基础运行环境 | 1 | [5.1](converse_design_doc_v2.md)、[5.2 架构示意](converse_design_doc_v2.md) | MVP 验收 全 |
| 3 | 终端底座 | 2 | [3.7 本地终端执行与 tmux](converse_design_doc_v2.md)、[4.2](converse_design_doc_v2.md) | 1、2、7 |
| 4 | 数据层与本地配置 | 2 | [5.4 数据模型](converse_design_doc_v2.md)、[5.5 输出存储](converse_design_doc_v2.md) | 11 |
| 5 | 风险检测核心库 | 2 | [3.10 危险命令风险分级](converse_design_doc_v2.md)、[8.4](converse_design_doc_v2.md) | 4 |
| 6 | tmux 会话生命周期 | 3、4 | [3.7](converse_design_doc_v2.md)、[3.8 文件夹→会话](converse_design_doc_v2.md)、[8.5](converse_design_doc_v2.md) | 1、2 |
| 7 | 三栏主界面与文件夹/会话管理 | 3、4、6 | [3.8](converse_design_doc_v2.md)、[4.1 三栏布局](converse_design_doc_v2.md)、[4.6 首次启动](converse_design_doc_v2.md) | 1、2 |
| 8 | 输入判定与执行流 | 3、5、7 | [3.3 输入判定](converse_design_doc_v2.md)、[3.5 失败处理](converse_design_doc_v2.md)、[4.3](converse_design_doc_v2.md)、[8.1](converse_design_doc_v2.md)、[8.3](converse_design_doc_v2.md) | 3、6、13 |
| 9 | AI 云端命令建议（含脱敏管线） | 4、7 | [3.2](converse_design_doc_v2.md)、[3.4](converse_design_doc_v2.md)、[5.3 AI 翻译策略](converse_design_doc_v2.md) | 4、5、14、15 |
| 10 | AI 建议卡片与风险确认 UI | 5、9 | [3.4](converse_design_doc_v2.md)、[3.10](converse_design_doc_v2.md)、[8.4](converse_design_doc_v2.md) | 4 |
| 11 | 终端模式与特殊输入 | 3 | [4.2](converse_design_doc_v2.md)、[4.4 sudo/密码](converse_design_doc_v2.md)、[8.2](converse_design_doc_v2.md) | 8、9 |
| 12 | Git 只读审查面板 | 4 | [3.9 Git 审查面板](converse_design_doc_v2.md) | 10 |
| 13 | 历史与输出摘要 | 4、9 | [3.6 历史的触达](converse_design_doc_v2.md)、[5.5](converse_design_doc_v2.md)、[8.6](converse_design_doc_v2.md) | 9、11、12 |
| 14 | 会话恢复异常处理 | 6、8 | [3.7](converse_design_doc_v2.md)、[六、边缘情况](converse_design_doc_v2.md) | 2 |
| 15 | MVP 集成验收与打包 | 全部 | [七、MVP 验收标准](converse_design_doc_v2.md) | 1-15 |

---

- [ ] 任务 1：Native Swift PoC（最高优先，风险闸门）

  > 技术栈为 macOS 原生 Swift（见设计文档 5.1）。投入 MVP 前先验证三个最高风险点；任何一项不通过则评估替代（自研终端 emulator 或回退方案）。**全部通过方可进入任务 2**。

  - [ ] 1.1 SwiftTerm 终端 PoC
    - [ ] 确认 SwiftTerm 许可证可用于闭源商业 App（MIT 直接用；LGPL 需动态链接 framework；不可接受则评估自研 VT100 解析）
    - [ ] SwiftTerm 接 posix pty（forkpty），稳定渲染 `ls`、`npm install` 进度、ANSI 颜色
    - [ ] 验证 `vim`、`top`、`less`、`python` REPL 能正常交互
    - [ ] 验证长输出滚动、resize、复制粘贴
  - [ ] 1.2 tmux 捆绑与会话恢复 PoC
    - [ ] 捆绑 tmux 二进制到 `.app/Contents/Resources/bin/`（ISC 许可可商用）
    - [ ] 绝对路径 posix_spawn 调起 `converse_<session_id>` 命名空间 tmux 会话
    - [ ] App 退出后重开 re-attach 到仍存在的 tmux 会话
    - [ ] 验证只操作 Converse namespace，不影响用户自建 tmux
  - [ ] 1.3 签名/公证/Paddle 最小闭环
    - [ ] Developer ID 签名 + notarytool 公证 + stapler 钉票据，Gatekeeper 放行
    - [ ] Hardened Runtime + 必要 entitlement（allow-unsigned-executable-memory 等）
    - [ ] Paddle license key 发放 + App 内激活验证最小流程
    - [ ] Sparkle 自动更新跑通
  - [ ] 验收：SwiftTerm 稳定跑 TUI；tmux 捆绑后重启恢复会话；签名公证后可下载安装并激活

- [ ] 任务 2：项目脚手架与基础运行环境

  - [ ] 初始化 SwiftUI App 工程（Swift + SwiftUI，macOS 13+）
  - [ ] 划分 SwiftUI 前端视图与 Swift 后端模块（终端/数据库/Git/AI）
  - [ ] 接入基础状态管理、路由（窗口/设置/onboarding）和样式系统
  - [ ] 配置 lint、format、typecheck（SwiftLint / swift-format）、基础测试命令
  - [ ] 验收：本地能启动原生桌面窗口，前端视图与后端模块能正常通信

- [ ] 任务 3：终端底座

  - [ ] 3.1 pty + shell 执行
    - [ ] 封装 `SessionPTY`（基于 `forkpty` / `posix_openpt`）
    - [ ] 启动默认 shell（`/bin/zsh`）
    - [ ] 支持写入命令、读取输出、发送 resize
    - [ ] 支持中断按钮发送 `Ctrl+C`（SIGINT）
  - [ ] 3.2 SwiftTerm 终端渲染
    - [ ] 中间区域渲染 SwiftTerm 终端视图
    - [ ] 支持 ANSI 颜色、进度刷新、滚动
    - [ ] 支持复制、粘贴、窗口尺寸变化
    - [ ] 长输出折叠 UI：超阈值显示摘要行，可展开
  - [ ] 3.3 tmux 会话验证
    - [ ] 检测捆绑的 tmux 二进制就位
    - [ ] 创建 `converse_<session_id>` tmux 会话；attach 到 pane
    - [ ] App 退出后重开可恢复
  - [ ] 验收：SwiftTerm 稳定连接 tmux-backed pty，`ls`/`npm install` 正常；`top`/`vim` 显示正常；长输出可折叠展开（底部输入框禁用、键盘直通放任务 11）

- [ ] 任务 4：数据层与本地配置

  - [ ] 建立 GRDB 初始化和 migration 机制
  - [ ] 实现 `Folder`、`Session`、`CommandRun`、`AiSuggestion`、`GitSnapshot`、`AppSetting` 表
  - [ ] schema：`Folder.disk_path/sort_order/is_archived`
  - [ ] schema：`Session.initial_cwd/current_cwd/shell_path/tmux_session_name/tmux_window_id/tmux_pane_id/status/restore_policy/closed_at/sort_order`
  - [ ] schema：`CommandRun.source/user_input/command_text/cwd_before/cwd_after/risk_level/confirmation_status/exit_code/output_excerpt/output_excerpt_truncated`
  - [ ] schema：`AiSuggestion.provider/model/prompt_version/natural_language_input/generated_command/explanation/risk_level/status`
  - [ ] schema：`GitSnapshot.repo_path/branch/status_json/selected_file/captured_at`
  - [ ] 配置读写：AI 模式、API base URL、模型名、强模型名、tmux namespace、输出摘要限制
  - [ ] 关键设置：`ai.provider`、`ai.api_key_ref`、`ai.routing_policy`、`risk.confirmation_policy`、`few_shot.keyword_match_limit`
  - [ ] 开发默认配置：`ai.provider=deepseek`、`ai.api_base_url=https://api.deepseek.com`、`ai.api_key_ref=env:DEEPSEEK_API_KEY`、`ai.model=deepseek-v4-flash`、`ai.strong_model=deepseek-v4-flash`
  - [ ] API key 安全存储：SQLite 只存 `api_key_ref`，真实 key 存 macOS Keychain
  - [ ] 支持本地开发从环境变量 `DEEPSEEK_API_KEY` 读取；key 不写入 Markdown/SQLite 明文/日志/AI 上下文
  - [ ] Swift 数据访问层（Record / Service 封装）+ migration 与字段级测试
  - [ ] 验收：重启 App 后配置/文件夹/会话元数据可恢复；DB 无明文 key；字段可持久化读取

- [ ] 任务 5：风险检测核心库

  - [ ] 实现风险分级：低、中、高、极高
  - [ ] 风险规则库：文件删除/覆盖、权限修改、网络脚本执行、磁盘操作、Git destructive
  - [ ] 基础 shell 命令解析：识别管道、重定向、`sudo`、多命令串联、危险参数
  - [ ] 输出结构化风险结果：等级、命中规则、影响范围、确认策略
  - [ ] `〔v2.1〕` 确认策略分档：`standard`（中风险仅提示）/ `strict`（中风险也需确认）
  - [ ] 中风险：standard 提示不破坏零摩擦；strict 进确认
  - [ ] 高风险强确认；极高风险倒计时确认
  - [ ] 风险规则单元测试：低/中/高/极高、管道、重定向、`sudo`、网络脚本、Git destructive
  - [ ] 验收：`rm -rf node_modules`、`git reset --hard`、`git clean -fdx`、`sudo rm`、`dd`、`mkfs`、网络脚本等产出正确等级与确认策略；直接输入高危命令不绕过检测

- [ ] 任务 6：tmux 会话生命周期核心

  - [ ] 会话创建：根据 Session 元数据创建 `converse_<session_id>` tmux 会话或 pane
  - [ ] attach：按 Session 绑定正确 tmux pane 并接入 pty
  - [ ] 切换会话：保留后台 tmux 状态，不 kill 原会话（切换即 detach）
  - [ ] 关闭会话：用户明确关闭时 kill tmux 并从列表移除
  - [ ] 状态同步：running / missing
  - [ ] 基础恢复：App 重启后按 SQLite 元数据重新 attach 仍存在的 Converse tmux 会话
  - [ ] `〔v2.1 8.5〕` 生命周期精简：列表仅 running/missing（移除 detached/closed 展示）；关闭即从列表移除不留灰条；无独立「分离」操作；missing 切入弹窗询问重新创建；顶栏动态统计「N 运行 · M 丢失」
  - [ ] 验收：创建/切换/关闭/重启恢复主路径可用；边缘情况放任务 14

- [ ] 任务 7：三栏主界面与文件夹/会话管理

  - [ ] 7.1 左侧文件夹与会话列表
    - [ ] 添加本地文件夹，支持选择目录和拖拽导入
    - [ ] 创建、重命名、切换、关闭会话
    - [ ] 文件夹和会话拖拽排序并持久化 `sort_order`
    - [ ] 展示 running / missing 状态
  - [ ] 7.2 中间终端与输入区布局
    - [ ] 集成终端显示区（SwiftTerm）
    - [ ] 集成底部输入框
    - [ ] 普通模式和终端模式 UI 状态
  - [ ] 7.3 基础设置页
    - [ ] AI 模式切换：关闭 / 建议 / 报错辅助
    - [ ] 云端 API 配置；API key 输入/更新/删除和安全存储状态
    - [ ] 显示 `DEEPSEEK_API_KEY` 环境变量可用性
    - [ ] 默认 shell 和 tmux namespace 配置
  - [ ] 7.4 首次启动流程（onboarding）
    - [ ] 欢迎页：说明真实终端底座 + AI 建议
    - [ ] 引导选择是否配置 AI
    - [ ] 引导选择第一个磁盘文件夹
    - [ ] 自动创建第一个 tmux-backed 会话
    - [ ] `〔v2.1 15.9〕` 4 步向导（功能→AI 配置→文件夹→就绪），首次启动记忆（不再弹）
  - [ ] 7.5 `⌘K` 全局搜索/跳转
    - [ ] 搜索文件夹和会话；选择后跳转
    - [ ] 空状态、无结果、键盘选择
    - [ ] `〔v2.1 15.8〕` 选中会话跨文件夹自动切换；`⌘R` 直接打开命令面板定位历史 Tab；历史/片段结果只填入输入框
    - [ ] `〔v2.1 15.8〕` 工作区右键：New Session / Edit（重命名工作区）/ Reveal in Finder / Close（移除侧栏不删磁盘）
    - [ ] 历史命令搜索接入放任务 13
  - [ ] `〔v2.1 15.7〕` 片段（Snippets）：左栏「+」新建（触发词+命令）；AI 卡片「存为片段」（AI 卡片在任务 10）；输入触发词回车即执行；带 ⌘1/⌘2 快捷键
  - [ ] 验收：完成首次启动、选文件夹、建会话、拖拽排序、切换；⌘K 跳转；工作区右键；片段新建

- [ ] 任务 8：输入判定与执行流

  - [ ] 8.1 输入框键盘行为
    - [ ] Enter 发送；Shift+Enter 换行
    - [ ] 单行上下键切换历史，多行优先移动光标
    - [ ] `Cmd+C` 复制选中文本
    - [ ] Tab 命令编辑态送 shell 或触发本地补全
  - [ ] 第一个 token 判定：builtin、alias、shell function、PATH 可执行、相对/绝对路径
  - [ ] 混合输入策略：`open 当前目录`、`git 看看状态` 优先 AI 或失败后修正
  - [ ] 明确命令直接写入 pty；接入任务 5 风险检测（高/极高拦截确认）
  - [ ] 非命令进 AI 流程占位（任务 9 完成前产生待处理事件）；AI 关闭/未配置时提示
  - [ ] AI 报错辅助模式：自然语言不主动翻译，失败后提供 AI 修正入口
  - [ ] 命令失败识别 `command not found`/语法错误/参数错误
  - [ ] 失败提供：重试原命令、编辑后重试、AI 修复建议
  - [ ] `〔v2.1 8.1/15.1〕` 输入辅助三层：①历史命令建议浮层（实时匹配，第一条高亮，↑↓ 选，回车/Tab 只填入不执行，suppress 防重弹）②无历史时命令补全（命令名/子命令/参数/路径，Tab 补全）③空输入 ↑↓ 切换历史
  - [ ] `〔v2.1 8.3/15.3〕` 流式执行与 Ctrl+C：命令先显示「执行中」；对话模式 `runningCmd` 存在时 Ctrl+C 中断 → `^C`/退出码 130，否则不破坏复制
  - [ ] 验收：`ls -la`/alias/function 直接执行；`列出大文件` 进 AI 占位；`gti status` 失败出现修复入口；输入三层辅助可用；Ctrl+C 可中断流式命令

- [ ] 任务 9：AI 云端命令建议（含脱敏管线）

  - [ ] 9.1 云端 API 客户端
    - [ ] 支持 OpenAI-compatible API；默认 DeepSeek
    - [ ] 默认模型和强模型配置
    - [ ] 从 Keychain 或 `DEEPSEEK_API_KEY` 读 key，不从 SQLite 明文读
    - [ ] `ai.api_key_ref=env:DEEPSEEK_API_KEY` 时直接用环境变量 key
    - [ ] 未配置状态：AI 不可用，引导配置
    - [ ] 服务不可用/超时/鉴权失败/限流：卡片显失败并提供重试
    - [ ] AI 故障时直接命令/终端/会话/Git 面板不受影响
  - [ ] 9.2 Prompt 与上下文注入
    - [ ] 注入 cwd、会话名、最近命令、exit code、输出摘要
    - [ ] **建立 AI 上下文脱敏管线**（统一在此实现，供任务 13 复用）：过滤 sudo 密码、API key、token、私钥、`.env` 内容
    - [ ] 设置页展示哪些上下文会发云端
    - [ ] 要求模型输出可执行 zsh 命令
  - [ ] 9.3 Few-shot 关键词检索
    - [ ] 纯文本示例库；关键词重叠或 TF-IDF Top-3 匹配；注入 Prompt
  - [ ] 将 AI 输出转为 AiSuggestion 记录，不直接执行
  - [ ] 调任务 5 风险检测为 AI 建议写风险等级和影响范围
  - [ ] `〔v2.1 15.10〕` 报错辅助模式：命令失败自动弹 AI 修复气泡（拼写纠错 / `brew install` / 追加排除路径），区别于建议模式的三动作菜单
  - [ ] 验收：自然语言生成命令建议对象；报错辅助仅失败后触发；无本地模型/embedding/向量库依赖；未配置或失败时终端路径可用；脱敏管线过滤敏感值

- [ ] 任务 10：AI 建议卡片与风险确认 UI

  - [ ] AI 建议卡片：用户原话、生成命令、风险等级、影响范围、执行/编辑/取消/**存为片段**（接任务 7 片段）
  - [ ] 用户点执行后才写入 tmux/pty
  - [ ] 用户编辑 AI 命令后调任务 5 重新判定风险
  - [ ] 中风险：AI 命令普通确认
  - [ ] 高风险强确认，展示影响范围（目标路径/Git destructive/批量删除）
  - [ ] 极高风险倒计时确认
  - [ ] `〔v2.1 8.4/15.4〕` 极高风险倒计时焦点落「取消」按钮，执行按钮 disabled，结束也不主动聚焦执行按钮
  - [ ] 更新 AiSuggestion 状态：proposed / accepted / edited / rejected / failed
  - [ ] 验收：AI 命令必须确认后执行；编辑后重新判风险；高/极高展示正确保护 UI；存为片段可用

- [ ] 任务 11：终端模式与特殊输入

  - [ ] 检测或手动进入 TUI/REPL 终端模式
  - [ ] `vim`、`top`、`less`、`python`、`node` 中禁用底部对话输入框
  - [ ] 终端模式键盘直通 pty
  - [ ] `〔v2.1 8.2/15.2〕` 键盘直通细化：vim 可编辑（按键插入/Backspace）；shell 可输命令回车/clear/exit；pager `q` 退出；REPL 输入回车/exit()；实时回显+闪烁光标
  - [ ] `〔v2.1 8.3〕` 终端模式 Ctrl+C 被 pty 接管中断当前命令（追加 `^C`+新提示符），不退出终端模式；vim 内无效
  - [ ] 退出后恢复普通对话增强模式
  - [ ] sudo 密码输入态：不显示、不存储、不发给 AI
  - [ ] 验收：TUI/REPL 可用且可编辑；sudo 密码不进历史/AI 上下文；Ctrl+C 行为正确

- [ ] 任务 12：Git 只读审查面板

  - [ ] 检测当前文件夹是否 Git 仓库
  - [ ] 显示当前分支
  - [ ] 显示 staged / unstaged 文件树
  - [ ] 显示选中文件 diff
  - [ ] 支持刷新和基础错误态
  - [ ] 验收：Git 面板只读，不提供 commit/push/checkout/reset 等按钮

- [ ] 任务 13：历史与输出摘要

  - [ ] 复用任务 9 脱敏管线，覆盖历史摘要、输入记录、运行日志
  - [ ] 保存命令来源、文本、cwd、exit code、风险等级、执行时间
  - [ ] 保存最近输出摘要，不保存完整大输出
  - [ ] `〔v2.1 8.6/15.6〕` 显示策略：新命令完整实时显示（实时徽章）；历史/恢复输出行数 > 400 显示头 200 + 尾 200，中间省略（历史徽章）；输出摘要限制固定不可改（8KB/200 行）
  - [ ] 历史触达三入口（无独立面板）：输入建议浮层 / `⌘K` 历史 Tab / ↑↓ 历史
  - [ ] 选中历史只填入输入框，不直接执行；双击同
  - [ ] 历史搜索接入 `⌘K`，结果只填入输入框
  - [ ] 验收：无直接执行/查看完整输出/收藏等动作；SQLite 不存完整大输出或敏感值；`⌘K` 历史结果只填入

- [ ] 任务 14：会话恢复异常处理

  - [ ] App 启动扫描 Converse namespace 下 tmux 会话
  - [ ] 扫描/attach/kill 只作用 Converse namespace，不影响用户自建 tmux
  - [ ] 在任务 6 基础恢复之上补齐异常分支
  - [ ] 识别 missing 会话并提供重新创建入口
  - [ ] 用户明确关闭 session 时 kill tmux
  - [ ] 删除文件夹不删磁盘目录；有运行会话时二次确认
  - [ ] 机器重启或 tmux server 异常退出：只恢复元数据，shell 状态标 missing
  - [ ] 验收：退出 App 不丢会话；明确关闭不恢复；tmux 被 kill 后 UI 状态正确；用户自建 tmux 不受影响

- [ ] 任务 15：MVP 集成验收与打包

  - [ ] 跑通首次启动：欢迎页、AI 配置、文件夹、首个会话
  - [ ] 跑通三条主流程：命令直执行、自然语言 AI 建议、失败 AI 修复
  - [ ] 跑通 `⌘K`/`⌘R` 跳转、输入三层辅助、tmux 恢复、历史填入、Git 只读、风险确认、终端模式编辑、Ctrl+C 中断
  - [ ] 基础错误提示和空状态
  - [ ] 验证 SQLite 无明文 key；sudo 密码/敏感上下文不进历史或 AI prompt
  - [ ] 单元测试：输入判定、风险分级（含 strict）、few-shot 检索、脱敏
  - [ ] 集成测试：tmux 恢复（退出恢复/关闭不恢复/kill 后 missing/非 Converse 不受影响）
  - [ ] 回归测试：历史只填入不执行
  - [ ] AI 异常态测试：未配置/超时/鉴权失败/限流时直接命令路径仍可用
  - [ ] macOS 打包（Developer ID 签名 + 公证 + Sparkle，见 5.6）
  - [ ] 验收：按设计文档 MVP 验收标准逐条通过

---

## 附录：v2.1 原型交互细化项归属表

> 这些项已落地于 `prototype.html`（设计文档第八章），工程实现时在上方对应主任务中完成，不作为独立阶段。`〔v2.1〕` 标注即下列各项。

| 细化项 | 归属任务 | 设计章节 |
| ------ | -------- | -------- |
| 输入辅助三层（历史建议浮层 / 命令补全 / 历史导航） | 任务 8 | 8.1 |
| 终端模式键盘直通（vim 编辑 / shell / REPL） | 任务 11 | 8.2 |
| Ctrl+C 与流式中断（终端/对话模式） | 任务 8 + 11 | 8.3 |
| 风险确认策略 standard/strict + 倒计时聚焦取消 | 任务 5 + 10 | 8.4 |
| 会话生命周期精简（移除 detached、关闭移除） | 任务 6 | 8.5 |
| 历史输出头尾截断（实时 vs 历史） | 任务 13 | 8.6 |
| 片段新建（左栏 + / AI 卡片存为片段） | 任务 7 + 10 | 8.7 |
| 搜索导航（⌘K 跳转 / ⌘R / 工作区右键） | 任务 7 | 8.8 |
| Onboarding 4 步向导 | 任务 7 | 15.9 |
| 报错辅助自动修复气泡 | 任务 9 | 8.9 |
