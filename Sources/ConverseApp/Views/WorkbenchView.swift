import SwiftUI
import ConverseCore

/// 根视图：未完成 onboarding 时显示欢迎向导占位；否则显示主工作台。
struct RootView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        ZStack {
            if state.hasCompletedOnboarding {
                WorkbenchView()
            } else {
                OnboardingView()
            }
            if state.showCommandPalette {
                CommandPaletteView(initialTab: state.paletteInitialTab)
            }
        }
        .background(Theme.bgApp)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Button("") {
                state.paletteInitialTab = .history
                state.showCommandPalette = true
            }
            .keyboardShortcut("r", modifiers: .command)
            .hidden()
        )
        .sheet(isPresented: $state.showSettings) { SettingsView() }
    }
}

/// 主工作台：顶部栏 + 四列（工作区/会话/中央/审查）。
struct WorkbenchView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            Divider().background(Theme.border)
            HStack(spacing: 0) {
                WorkspaceBar()
                    .frame(width: 58)
                Divider().background(Theme.border)
                SessionSidebar()
                    .frame(width: 270)
                Divider().background(Theme.border)
                MainColumn()
                Divider().background(Theme.border)
                ReviewPanel()
                    .frame(width: 330)
            }
        }
    }
}

struct TopBar: View {
    @EnvironmentObject var state: AppState
    @State private var runningCount: Int = 0
    @State private var missingCount: Int = 0

    var body: some View {
        HStack(spacing: Theme.Spacing.s7) {
            Text("Converse").font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            Button {
                state.paletteInitialTab = .sessions
                state.showCommandPalette.toggle()
            } label: {
                HStack(spacing: Theme.Spacing.s3) {
                    Image(systemName: "magnifyingglass")
                    Text("搜索会话、命令…").foregroundStyle(Theme.textTertiary)
                    Text("⌘K").font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.s7).padding(.vertical, Theme.Spacing.s3)
            .background(Theme.bgSubtle, in: RoundedRectangle(cornerRadius: Theme.Radius.md))

            Spacer()

            Text("\(runningCount) 运行 · \(missingCount) 丢失")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)

            Picker("", selection: $state.aiMode) {
                ForEach(AiMode.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented).frame(width: 240)

            Button { state.showSettings = true } label: {
                Image(systemName: "gearshape").foregroundStyle(Theme.textSecondary)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.s9).frame(height: 42)
        .background(Theme.bgApp)
        .onAppear { refreshStatus() }
    }

    private func refreshStatus() {
        let ids = TmuxManager().listConverseSessions()
        runningCount = ids.count
        missingCount = 0
    }
}

struct WorkspaceBar: View {
    var body: some View {
        Theme.bgSurface
    }
}

struct SessionSidebar: View {
    var body: some View {
        SidebarView()
    }
}

private struct PendingShellConfirm: Identifiable {
    let id = UUID()
    let command: String
    let assessment: RiskAssessment
}

struct MainColumn: View {
    @EnvironmentObject var state: AppState
    @StateObject private var terminalController = TerminalController()
    @State private var pendingSuggestion: AiCommandSuggestion?
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var lastQuery: String?
    @State private var pendingConfirm: PendingShellConfirm?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let session = state.selectedSession() {
                    let sid = state.tmuxShortID(for: session)
                    SwiftTerminalView(
                        directory: session.currentCwd,
                        tmuxSessionID: sid,
                        onProcessTerminated: { _ in },
                        controller: terminalController
                    )
                    .id(sid)
                } else {
                    VStack(spacing: Theme.Spacing.s6) {
                        Image(systemName: "terminal").font(.system(size: 32)).foregroundStyle(Theme.textTertiary)
                        Text("选择或新建一个会话").foregroundStyle(Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.bgSurface)
                }
                if aiLoading {
                    VStack(spacing: Theme.Spacing.s3) {
                        ProgressView().controlSize(.small)
                        Text("AI 思考中…").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                    }
                    .padding(Theme.Spacing.s6)
                    .background(Theme.bgSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border))
                }
            }
            .overlay(alignment: .topTrailing) {
                if terminalController.terminalMode || terminalController.awaitingPassword {
                    VStack(spacing: Theme.Spacing.s2) {
                        if terminalController.terminalMode {
                            HStack(spacing: Theme.Spacing.s3) {
                                Image(systemName: "terminal")
                                    .font(.system(size: 11))
                                Text("终端模式")
                                    .font(.system(size: 11, weight: .medium))
                                Button("退出") { terminalController.exitTerminalMode() }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, Theme.Spacing.s4)
                            .padding(.vertical, Theme.Spacing.s2)
                            .background(Theme.warning, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
                        }
                        if terminalController.awaitingPassword {
                            Text("正在输入密码（不记录、不发 AI）")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal, Theme.Spacing.s4)
                                .padding(.vertical, Theme.Spacing.s2)
                                .background(Theme.bgSubtle, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.s4)
                    .padding(.top, Theme.Spacing.s3)
                }
            }
            Divider().background(Theme.border)
            if let pendingSuggestion {
                AiSuggestionCard(
                    suggestion: pendingSuggestion,
                    controller: terminalController,
                    onDismiss: { self.pendingSuggestion = nil },
                    onEdit: { reassess($0) }
                )
            }
            if let aiError {
                HStack(spacing: Theme.Spacing.s3) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Theme.danger)
                        .font(.system(size: 12))
                    Text(aiError)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.danger)
                    Spacer()
                    if lastQuery != nil {
                        Button("重试") { if let q = lastQuery { handleAI(q) } }
                            .buttonStyle(.plain)
                            .font(.system(size: 12))
                    }
                }
                .padding(.horizontal, Theme.Spacing.s9)
                .padding(.vertical, Theme.Spacing.s3)
                .background(Theme.dangerSoft)
            }
            InputBar(
                controller: terminalController,
                onNaturalLanguage: handleAI,
                onShellConfirm: { cmd, assessment in
                    pendingConfirm = PendingShellConfirm(command: cmd, assessment: assessment)
                },
                disabled: terminalController.terminalMode
            )
        }
        .background(Theme.bgSurface)
        .sheet(item: $pendingConfirm) { pc in
            RiskConfirmDialog(
                command: pc.command,
                level: pc.assessment.level,
                impactScope: pc.assessment.impactScope,
                onConfirm: {
                    terminalController.run(pc.command)
                    pendingConfirm = nil
                },
                onCancel: { pendingConfirm = nil }
            )
        }
    }

    private func handleAI(_ text: String) {
        let settings = state.settings
        let cwd = state.selectedSession()?.currentCwd ?? ""
        lastQuery = text
        Task {
            aiLoading = true
            aiError = nil
            defer { aiLoading = false }
            guard let apiKey = KeychainStoreResolve.resolveApiKey(ref: settings.apiKeyRef),
                  !apiKey.isEmpty else {
                aiError = "未配置 API key，请在设置中填写"
                return
            }
            let config = AiConfig(
                apiBaseUrl: settings.apiBaseUrl,
                model: settings.model,
                apiKey: apiKey,
                promptVersion: "v1"
            )
            let advisor = CommandAdvisor(client: AiClient(config: config))
            do {
                pendingSuggestion = try await advisor.suggest(
                    naturalLanguage: text,
                    context: cwd,
                    policy: settings.confirmationPolicy
                )
            } catch let e as AiError {
                aiError = friendlyError(e)
            } catch {
                aiError = "请求失败：\(error.localizedDescription)"
            }
        }
    }

    private func reassess(_ newCommand: String) {
        guard let old = pendingSuggestion else { return }
        let a = RiskDetector().assess(newCommand, policy: state.settings.confirmationPolicy)
        pendingSuggestion = AiCommandSuggestion(
            command: newCommand,
            explanation: old.explanation,
            riskLevel: a.level,
            impactScope: a.impactScope,
            requiresConfirmation: a.requiresConfirmation,
            provider: old.provider,
            model: old.model,
            promptVersion: old.promptVersion
        )
    }

    private func friendlyError(_ e: AiError) -> String {
        switch e {
        case .notConfigured: return "AI 未配置，请在设置中填写 API key"
        case .unauthorized: return "API key 无效或已过期（401）"
        case .rateLimited: return "请求过于频繁，请稍后再试（429）"
        case .http(let code): return "服务异常（HTTP \(code)）"
        case .transport(let msg): return "网络错误：\(msg)"
        case .decodeFailed: return "AI 返回格式异常，请重试"
        }
    }
}

struct ReviewPanel: View {
    var body: some View {
        GitPanel(repoPath: "/Volumes/mac2/projects/git_repo/run_self/converse2")
    }
}
