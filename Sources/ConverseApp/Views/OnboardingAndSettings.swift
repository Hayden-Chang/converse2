import SwiftUI
import AppKit
import ConverseCore

struct OnboardingView: View {
    @EnvironmentObject var state: AppState
    @State private var step: Int = 0
    @State private var aiMode: AiMode = .suggest
    @State private var pickedName: String = ""
    @State private var pickedPath: String = ""

    var body: some View {
        VStack(spacing: 0) {
            stepDots
            Divider().background(Theme.border)
            Group {
                switch step {
                case 0: step0
                case 1: step1
                case 2: step2
                default: step3
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider().background(Theme.border)
            footer
        }
        .frame(width: 600, height: 460)
        .background(Theme.bgApp)
    }

    private var stepDots: some View {
        HStack(spacing: Theme.Spacing.s3) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i == step ? Theme.primary : Theme.borderStrong)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, Theme.Spacing.s6)
    }

    private var step0: some View {
        VStack(spacing: Theme.Spacing.s9) {
            Text("欢迎使用 Converse").font(.system(size: 24, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            VStack(alignment: .leading, spacing: Theme.Spacing.s7) {
                featureRow("terminal", "真实终端为底座", "原生 shell + tmux，脱离 AI 仍是完整终端")
                featureRow("sparkles", "AI 命令建议", "自然语言翻译成命令，透明可确认")
                featureRow("folder", "文件夹会话组织", "按项目归集会话，有归属有上下文")
                featureRow("eye", "Git 审查", "侧栏只读 diff，不改动你的仓库")
            }
            .frame(maxWidth: 440)
        }
    }

    private var step1: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s7) {
            Text("选择 AI 模式").font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            ForEach(AiMode.allCases, id: \.self) { mode in
                modeOption(mode)
            }
        }
        .frame(maxWidth: 440)
    }

    private var step2: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s7) {
            Text("添加第一个文件夹").font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            Text("选择一个工作目录，将为其创建「主会话」。可跳过稍后再加。")
                .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            Button {
                pickFolder()
            } label: {
                HStack(spacing: Theme.Spacing.s4) {
                    Image(systemName: "folder.badge.plus")
                    Text(pickedPath.isEmpty ? "选择目录…" : pickedPath)
                        .lineLimit(1).truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.s7)
                .background(Theme.bgSubtle, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
            }
            .buttonStyle(.plain)
            if !pickedPath.isEmpty {
                TextField("文件夹显示名（可选）", text: $pickedName)
                    .textFieldStyle(.roundedBorder)
            }
            Spacer()
        }
        .frame(maxWidth: 440)
    }

    private var step3: some View {
        VStack(spacing: Theme.Spacing.s9) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 40)).foregroundStyle(Theme.success)
            Text("一切就绪").font(.system(size: 22, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            Text("开始用对话和命令高效操作终端。").foregroundStyle(Theme.textSecondary)
        }
    }

    private var footer: some View {
        HStack {
            if step > 0 && step < 3 {
                Button("上一步") { step -= 1 }.buttonStyle(.plain).foregroundStyle(Theme.textSecondary)
            }
            if step == 1 {
                Button("跳过") {
                    try? state.settings.setString(SettingsService.Key.aiMode, AiMode.suggest.rawValue)
                    state.aiMode = .suggest
                    step = 2
                }.foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            if step < 3 {
                Button(step == 2 ? "完成" : "下一步") { advance() }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("开始使用") { state.completeOnboarding() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, Theme.Spacing.s9).padding(.vertical, Theme.Spacing.s6)
    }

    private func advance() {
        if step == 1 {
            try? state.settings.setString(SettingsService.Key.aiMode, aiMode.rawValue)
            state.aiMode = aiMode
        } else if step == 2 {
            commitFolder()
        }
        step += 1
    }

    private func commitFolder() {
        guard !pickedPath.isEmpty else { return }
        let name = pickedName.trimmingCharacters(in: .whitespaces).isEmpty
            ? (pickedPath as NSString).lastPathComponent
            : pickedName.trimmingCharacters(in: .whitespaces)
        state.addFolder(name: name, diskPath: pickedPath)
        if let folder = state.folders.last {
            state.createSession(in: folder, name: "主会话")
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "选择"
        if panel.runModal() == .OK, let url = panel.url {
            pickedPath = url.path
            pickedName = url.lastPathComponent
        }
    }

    private func featureRow(_ icon: String, _ title: String, _ desc: String) -> some View {
        HStack(spacing: Theme.Spacing.s7) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Theme.primary).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text(desc).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    private func modeOption(_ mode: AiMode) -> some View {
        let selected = aiMode == mode
        return Button {
            aiMode = mode
        } label: {
            HStack(spacing: Theme.Spacing.s6) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? Theme.primary : Theme.textTertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.label).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                    Text(modeDesc(mode)).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(Theme.Spacing.s7)
            .background(selected ? Theme.primarySoft : Theme.bgSubtle,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        }
        .buttonStyle(.plain)
    }

    private func modeDesc(_ mode: AiMode) -> String {
        switch mode {
        case .off: "不调用 AI，纯终端使用"
        case .suggest: "自然语言翻译为命令，需确认后执行"
        case .errorAssist: "仅在命令失败时报错分析与建议"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @State private var aiMode: AiMode = .suggest
    @State private var apiBaseUrl: String = ""
    @State private var model: String = ""
    @State private var strongModel: String = ""
    @State private var apiKey: String = ""
    @State private var defaultShell: String = ""
    @State private var tmuxNamespace: String = ""

    private var settings: SettingsService { state.settings }
    private var envKeyAvailable: Bool {
        ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"] != nil
    }

    var body: some View {
        TabView {
            aiTab.tabItem { Label("AI", systemImage: "cpu") }
            terminalTab.tabItem { Label("终端", systemImage: "terminal") }
        }
        .frame(width: 480, height: 380)
        .onAppear { load() }
    }

    private var aiTab: some View {
        Form {
            Picker("AI 模式", selection: $aiMode) {
                ForEach(AiMode.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            .onChange(of: aiMode) { newMode in
                try? settings.setString(SettingsService.Key.aiMode, newMode.rawValue)
                state.aiMode = newMode
            }

            TextField("API Base URL", text: $apiBaseUrl)
                .onSubmit { try? settings.setString(SettingsService.Key.apiBaseUrl, apiBaseUrl) }
            TextField("模型", text: $model)
                .onSubmit { try? settings.setString(SettingsService.Key.model, model) }
            TextField("强模型", text: $strongModel)
                .onSubmit { try? settings.setString(SettingsService.Key.strongModel, strongModel) }

            SecureField("API Key（存入 Keychain）", text: $apiKey)
                .onSubmit {
                    if apiKey.isEmpty {
                        KeychainStore.delete("deepseek_api_key")
                    } else {
                        KeychainStore.set(apiKey, for: "deepseek_api_key")
                    }
                }

            HStack(spacing: Theme.Spacing.s3) {
                Circle().fill(envKeyAvailable ? Theme.success : Theme.textTertiary).frame(width: 8, height: 8)
                Text(envKeyAvailable ? "环境变量 DEEPSEEK_API_KEY 可用" : "环境变量未配置（可手填 Key）")
                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
            Text("当前引用：\(settings.apiKeyRef)")
                .font(.system(size: 11)).foregroundStyle(Theme.textTertiary)
        }
        .padding(Theme.Spacing.s9)
    }

    private var terminalTab: some View {
        Form {
            TextField("默认 Shell", text: $defaultShell)
                .onSubmit { try? settings.setString(SettingsService.Key.defaultShell, defaultShell) }
            TextField("tmux 命名空间", text: $tmuxNamespace)
                .onSubmit { try? settings.setString(SettingsService.Key.tmuxNamespace, tmuxNamespace) }
        }
        .padding(Theme.Spacing.s9)
    }

    private func load() {
        aiMode = settings.aiMode
        apiBaseUrl = settings.apiBaseUrl
        model = settings.model
        strongModel = settings.strongModel
        apiKey = KeychainStore.get("deepseek_api_key") ?? ""
        defaultShell = settings.defaultShell
        tmuxNamespace = settings.tmuxNamespace
    }
}
