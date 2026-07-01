# Converse 界面设计风格说明

## 1. 整体风格定位

### 风格关键词

- 轻量工作台
- 开发者工具
- 极简低对比
- 信息密集
- macOS 原生感

### 产品类型判断

该界面更接近 **开发者工具 + 聊天式 IDE + 终端工作台**。它不是传统聊天工具，也不是管理后台；核心体验是围绕会话、命令执行、代码状态、Git 审查和 AI 辅助形成的多面板工作区。

### 整体气质

整体气质专业、克制、轻量、偏技术向。界面以浅灰白背景、低饱和边框、蓝色主操作和绿色运行状态为主，减少强装饰感，强调可读性和工作流连续性。视觉上接近 macOS 工具软件：面板干净、阴影轻、圆角适中、状态标签小而明确。

## 2. 布局结构

### 页面整体分区

桌面端采用横向工作台式布局，主要分为五个区域：

1. 顶部全局栏：应用名、全局搜索、AI 模式切换、运行状态、主题/设置入口。
2. 最左工作区栏：竖向 workspace 图标列表，承载项目切换。
3. 左侧会话栏：当前项目、路径、分支状态、新建会话按钮、会话列表、信任级别、片段列表。
4. 中央主内容区：会话标题、终端/命令输出流、用户命令气泡、底部输入区。
5. 右侧审查面板：Git 审查、上下文、分支、文件变更、diff 预览。

### 比例关系

以 1920px 宽截图为参考：

- 顶部栏高度：约 42px。
- 最左工作区栏宽度：约 58px。
- 左侧会话栏宽度：约 270px。
- 中央主内容区宽度：约 1260px，承担主要阅读和输入。
- 右侧面板宽度：约 330px。
- 底部输入区高度：约 125-150px。

### 信息密度

信息密度为 **中高**。中央区域保留较大留白用于命令流阅读，但左侧栏、底部输入、右侧 Git 面板承载了较多状态信息、快捷键、标签和操作入口。它是典型工作台布局，而非营销页或单一聊天页面。

### 工作台特征

- 固定侧栏 + 固定右侧检查面板。
- 中央内容可滚动。
- 底部输入区常驻。
- 状态和上下文标签贴近输入框。
- 顶部提供全局模式切换与设置入口。

## 3. 颜色系统

以下 HEX 为根据截图近似提取的设计 token，可用于复刻。

### 基础颜色

| Token | HEX | 用途 |
| --- | --- | --- |
| `--color-bg-app` | `#F6F6FA` | 应用整体背景、侧栏背景 |
| `--color-bg-surface` | `#FFFFFF` | 主内容区域、卡片、菜单、弹窗 |
| `--color-bg-subtle` | `#F1F1F7` | 输入框、代码块、弱背景 |
| `--color-bg-muted` | `#E8E8F1` | 终端输出头部、选中列表背景 |
| `--color-border` | `#E3E4EC` | 常规分割线和边框 |
| `--color-border-strong` | `#D4D7E2` | 重点面板边框、菜单边框 |
| `--color-text-primary` | `#171923` | 标题、主要文字 |
| `--color-text-secondary` | `#667085` | 正文辅助信息 |
| `--color-text-tertiary` | `#9AA1B5` | 路径、说明、弱标签 |
| `--color-text-disabled` | `#B8BDCC` | 禁用文字 |

### 品牌与状态色

| Token | HEX | 用途 |
| --- | --- | --- |
| `--color-primary` | `#3F7DED` | 主按钮、发送按钮、选中 Tab、用户命令气泡 |
| `--color-primary-hover` | `#2F6FE4` | 主按钮 hover |
| `--color-primary-active` | `#255FD0` | 主按钮 pressed |
| `--color-primary-soft` | `#E8F0FF` | 蓝色浅底标签、选中弱背景 |
| `--color-success` | `#22C55E` | 运行中、成功、可用状态 |
| `--color-success-soft` | `#EAF8EF` | 成功提示条背景 |
| `--color-danger` | `#F05265` | 失败、错误、小红点 |
| `--color-danger-soft` | `#FFECEF` | 失败标签背景 |
| `--color-warning` | `#F5B301` | 文件 modified 标识、注意状态 |
| `--color-overlay` | `rgba(0, 0, 0, 0.45)` | Modal 背景遮罩 |

### 颜色使用规律

- 蓝色只用于最高优先级操作和选中态：发送、AI 建议、当前 Tab、用户命令气泡。
- 绿色用于执行成功、运行中、环境变量可用、退出码为 0。
- 红色用于失败、丢失状态、错误提醒和 workspace 小红点。
- 黄色用于 Git modified、提示性文件状态。
- 背景以 `#F6F6FA`、`#FFFFFF`、`#F1F1F7` 三级灰白层级构建，不使用大面积高饱和色。

## 4. 字体与文字

### 字体气质

字体接近系统默认 UI 字体，气质清晰、理性、工具化。中文和英文混排时不做强风格化处理，保持 macOS 原生 San Francisco / PingFang SC 的阅读感。

推荐字体栈：

```css
font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC",
  "Segoe UI", sans-serif;
```

代码和终端区域推荐：

```css
font-family: "SF Mono", Menlo, Monaco, Consolas, "Liberation Mono", monospace;
```

### 字号建议

| Token | Size | Line Height | Weight | 用途 |
| --- | --- | --- | --- | --- |
| `--font-size-xs` | `10px` | `14px` | 400/500 | 快捷键、极弱标签 |
| `--font-size-sm` | `12px` | `16px` | 400/500 | 辅助文字、路径、Badge |
| `--font-size-md` | `14px` | `20px` | 400/500 | 正文、按钮、输入框 |
| `--font-size-lg` | `16px` | `22px` | 600 | 会话标题、项目名 |
| `--font-size-xl` | `18px` | `24px` | 600 | 弹窗标题或重要标题 |
| `--font-size-code` | `12px` | `20px` | 400 | 终端输出、diff、命令 |

### 排版特点

- 字重克制，标题多为 600，正文为 400，按钮/标签为 500。
- 字间距保持默认，不使用负字距。
- 辅助文字大量使用低对比灰色。
- 代码区域行高较宽松，便于连续扫描。
- 中英文混排不额外加粗英文，路径和命令使用等宽字体或弱色显示。

## 5. 组件风格

### 按钮

- 主按钮：蓝底白字，圆角 `8px`，高度 `36-40px`，水平 padding `16-18px`。
- 次按钮：浅灰底或白底，灰色文字，边框 `1px solid #E3E4EC`。
- 分段按钮：多个按钮共享浅灰容器，选中项蓝底白字，未选中为灰底灰字。
- 图标按钮：透明或浅灰底，尺寸 `28-32px`，圆角 `6-8px`。
- hover：背景加深 4-8%，边框略增强。
- active：主色更深，轻微内收感，不使用明显缩放。
- disabled：文字 `#B8BDCC`，背景 `#F1F1F7`，无阴影。

### 输入框

- 背景：`#F1F1F7` 或 `#FFFFFF`。
- 边框：默认 `#E3E4EC`，focus 使用 `#3F7DED`。
- 圆角：`8px`。
- 高度：单行 `36-40px`，底部输入框约 `40px` 高。
- placeholder：`#9AA1B5`。
- focus：蓝色 1px 描边，可加轻微 `0 0 0 2px rgba(63, 125, 237, 0.12)`。

### 标签 / Badge

- 尺寸小，字号 `10-12px`。
- 圆角 `4-6px`。
- padding `2px 6px`。
- 运行中：绿字 + 浅绿底。
- 失败：红字 + 浅红底。
- 分支/模型/路径标签：灰蓝文字 + 浅灰底。
- 当前选择：蓝字或蓝底白字，取决于优先级。

### 卡片 / 面板

- 主面板通常不做重卡片化，依靠背景分区和细边框。
- 终端输出块是浅灰紫背景，圆角 `6px`，边框 `#E3E4EC`。
- 右侧 diff 预览为白底卡片，圆角 `6px`，细边框。
- 阴影非常轻，仅用于浮层、菜单、弹窗和新建会话按钮。

### 侧边栏

- 最左 workspace 栏：窄列，白/浅灰背景，图标为带色块的字母头像。
- 左侧会话栏：浅灰背景，顶部项目名清晰，路径弱化。
- 会话列表项：选中态为 `#E8E8F1` 或类似浅灰紫，右侧显示状态 Badge。
- 图标头像圆角 `8-10px`，当前 workspace 有深色描边。

### Tab

- 顶部/右侧 Tab 使用文字型 Tab。
- 选中态：蓝色文字 + 底部 2px 蓝色指示线。
- 未选中：灰色文字，无背景。
- Tab 高度约 `36-40px`，间距 `20-28px`。

### 弹窗 / Modal

- 居中白色面板，宽度约 `620px`。
- 圆角 `10-12px`。
- 背景遮罩 `rgba(0, 0, 0, 0.45)`。
- 阴影：柔和大阴影，突出层级但不厚重。
- 内容采用表单行结构：左侧 label，右侧控件，行间用细线分隔。
- 底部右对齐主按钮。

### 下拉菜单

- 白底，圆角 `6-8px`。
- 边框 `#D4D7E2`。
- 阴影中等：`0 8px 24px rgba(15, 23, 42, 0.12)`。
- 菜单项高度 `28-34px`，padding `8px 12px`。
- 禁用项文字浅灰。
- 分组之间使用 `1px` 分割线。

### 代码块 / 终端输出区域

- 容器背景：`#F1F1F7`。
- 头部背景稍深：`#E6E7F0`。
- 圆角：`6px`。
- 字体：等宽 `12px`，行高 `20px`。
- 退出码成功显示为绿色右对齐。
- 用户输入命令以蓝色气泡右对齐，内容使用等宽字体。
- 历史命令弹层使用蓝色边框和浅蓝选中行。

## 6. 交互与状态表达

### 选中态

- 当前 Tab：蓝色文字 + 蓝色下划线。
- 当前会话：浅灰紫背景 + 更深正文。
- 当前 workspace：头像外层深色描边。
- 当前分段按钮：蓝底白字。
- 历史命令选中：浅蓝灰背景 + 蓝色边框容器。

### 运行中、失败、成功、禁用

- 运行中：绿色 Badge，常显示“运行”。
- 成功：绿色文字，例如“退出码 0”、绿色提示条。
- 失败：红色 Badge 或红色小状态点，文字可显示“丢失”。
- 禁用：浅灰文字、浅灰背景，不出现 hover 强反馈。
- 只读/警告：锁图标 + 灰紫提示条，不使用强红色，避免误判为错误。

### 层级关系

- 第一层：应用背景 `#F6F6FA`。
- 第二层：内容和侧栏 `#FFFFFF` / `#F6F6FA`。
- 第三层：输入、代码块、列表项 `#F1F1F7`。
- 第四层：浮层、菜单、Modal 使用白底 + 阴影。
- 重要操作通过蓝色而非阴影表达。
- 弱信息通过透明度和灰色文字表达。

## 7. 可复刻设计规范

### Spacing Scale

```css
:root {
  --space-1: 2px;
  --space-2: 4px;
  --space-3: 6px;
  --space-4: 8px;
  --space-5: 10px;
  --space-6: 12px;
  --space-7: 16px;
  --space-8: 20px;
  --space-9: 24px;
  --space-10: 32px;
}
```

使用规则：

- 紧凑标签内部：`2-6px`。
- 按钮和输入框内部：`8-16px`。
- 列表项间距：`6-10px`。
- 面板内边距：`12-16px`。
- 主内容左右留白：`24px`。
- 命令流块之间：`28-44px`，形成可扫描节奏。

### Border Radius

```css
:root {
  --radius-xs: 4px;
  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 10px;
  --radius-xl: 12px;
  --radius-pill: 999px;
}
```

使用规则：

- Badge：`4-6px`。
- 小按钮、输入框、代码块：`6-8px`。
- 头像/workspace 图标：`8-10px`。
- Modal：`10-12px`。
- 不使用过大的圆角，避免偏移动端或玩具感。

### Shadow

```css
:root {
  --shadow-sm: 0 1px 2px rgba(15, 23, 42, 0.06);
  --shadow-md: 0 6px 18px rgba(15, 23, 42, 0.10);
  --shadow-lg: 0 18px 48px rgba(15, 23, 42, 0.18);
}
```

使用规则：

- 普通面板不用阴影，使用边框。
- 新建会话按钮可用 `--shadow-sm`。
- 下拉菜单使用 `--shadow-md`。
- Modal 使用 `--shadow-lg`。

### Color Tokens

```css
:root {
  --color-bg-app: #f6f6fa;
  --color-bg-surface: #ffffff;
  --color-bg-subtle: #f1f1f7;
  --color-bg-muted: #e8e8f1;

  --color-border: #e3e4ec;
  --color-border-strong: #d4d7e2;

  --color-text-primary: #171923;
  --color-text-secondary: #667085;
  --color-text-tertiary: #9aa1b5;
  --color-text-disabled: #b8bdcc;

  --color-primary: #3f7ded;
  --color-primary-hover: #2f6fe4;
  --color-primary-active: #255fd0;
  --color-primary-soft: #e8f0ff;

  --color-success: #22c55e;
  --color-success-soft: #eaf8ef;
  --color-danger: #f05265;
  --color-danger-soft: #ffecef;
  --color-warning: #f5b301;

  --color-overlay: rgba(0, 0, 0, 0.45);
}
```

### Typography Tokens

```css
:root {
  --font-sans: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC",
    "Segoe UI", sans-serif;
  --font-mono: "SF Mono", Menlo, Monaco, Consolas, "Liberation Mono", monospace;

  --text-xs: 10px;
  --text-sm: 12px;
  --text-md: 14px;
  --text-lg: 16px;
  --text-xl: 18px;

  --leading-xs: 14px;
  --leading-sm: 16px;
  --leading-md: 20px;
  --leading-lg: 22px;
  --leading-xl: 24px;

  --weight-regular: 400;
  --weight-medium: 500;
  --weight-semibold: 600;
}
```

### Component Style Rules

```css
.app-shell {
  background: var(--color-bg-app);
  color: var(--color-text-primary);
  font-family: var(--font-sans);
  font-size: var(--text-md);
}

.top-bar {
  height: 42px;
  background: var(--color-bg-app);
  border-bottom: 1px solid var(--color-border);
}

.sidebar {
  background: var(--color-bg-app);
  border-right: 1px solid var(--color-border);
}

.main-panel {
  background: var(--color-bg-surface);
}

.right-panel {
  width: 330px;
  background: var(--color-bg-app);
  border-left: 1px solid var(--color-border);
}

.button-primary {
  height: 36px;
  padding: 0 16px;
  border: 0;
  border-radius: var(--radius-md);
  background: var(--color-primary);
  color: #fff;
  font-weight: var(--weight-medium);
}

.button-primary:hover {
  background: var(--color-primary-hover);
}

.input {
  height: 38px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-bg-subtle);
  color: var(--color-text-primary);
  padding: 0 12px;
}

.input:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px rgba(63, 125, 237, 0.12);
}

.badge {
  display: inline-flex;
  align-items: center;
  height: 20px;
  padding: 0 6px;
  border-radius: var(--radius-sm);
  font-size: var(--text-xs);
  font-weight: var(--weight-medium);
}

.badge-success {
  background: var(--color-success-soft);
  color: var(--color-success);
}

.terminal-block {
  overflow: hidden;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-bg-subtle);
  font-family: var(--font-mono);
  font-size: 12px;
  line-height: 20px;
}

.terminal-header {
  height: 30px;
  background: var(--color-bg-muted);
  color: var(--color-text-tertiary);
  padding: 0 12px;
}

.modal-backdrop {
  background: var(--color-overlay);
}

.modal {
  width: 620px;
  border-radius: var(--radius-xl);
  background: var(--color-bg-surface);
  box-shadow: var(--shadow-lg);
}
```

### 复刻注意事项

- 控制整体对比度，不要把边框、阴影、背景做得过重。
- 主色蓝只用于真正可行动或当前选中的元素。
- 代码、路径、模型、会话上下文应尽量使用小字号和灰蓝色。
- 右侧面板保持窄而密，中央区域保持宽而可读。
- 交互反馈以颜色和细描边为主，避免大幅动画。
- Modal 遮罩较深，但弹窗本身仍保持白底、轻圆角、低装饰。
