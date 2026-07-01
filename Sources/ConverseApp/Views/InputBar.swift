import SwiftUI
import ConverseCore

struct InputBar: View {
    let controller: TerminalController
    var onNaturalLanguage: (String) -> Void
    var onShellConfirm: (String, RiskAssessment) -> Void
    var disabled: Bool = false

    @EnvironmentObject var state: AppState
    @State private var history: [String] = []
    @State private var historyIndex: Int? = nil
    @State private var hint: String? = nil
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
            if disabled {
                Text("交互式程序运行中，键盘已直通终端")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, Theme.Spacing.s9)
            } else if let hint {
                Text(hint)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.warning)
                    .padding(.horizontal, Theme.Spacing.s9)
            }
            HStack(spacing: Theme.Spacing.s4) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textTertiary)
                    .font(.system(size: 11))
                TextField("说点什么或打个命令…", text: $state.inputDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($focused)
                    .onSubmit(submit)
                    .disabled(disabled)
                    .onChange(of: state.inputFocusToken) { _ in focused = true }
                HStack(spacing: Theme.Spacing.s3) {
                    Button { navigateHistory(-1) } label: {
                        Image(systemName: "chevron.up").font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(history.isEmpty || disabled)
                    Button { navigateHistory(1) } label: {
                        Image(systemName: "chevron.down").font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(history.isEmpty || disabled)
                    Divider().frame(height: 14)
                    Button { controller.interrupt() } label: {
                        Image(systemName: "stop.fill")
                            .foregroundStyle(Theme.danger)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.s9)
            .padding(.vertical, Theme.Spacing.s4)
        }
        .background(Theme.bgSurface)
    }

    private func navigateHistory(_ dir: Int) {
        guard !history.isEmpty else { return }
        let cur = historyIndex ?? history.count
        var idx = cur + dir
        idx = min(max(idx, 0), history.count)
        if idx < history.count {
            state.inputDraft = history[idx]
            historyIndex = idx
        } else {
            state.inputDraft = ""
            historyIndex = nil
        }
    }

    private func submit() {
        let trimmed = state.inputDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        pushHistory(trimmed)
        let classifier = InputClassifier(pathDirs: currentPathDirs())
        switch classifier.classify(trimmed) {
        case .shellCommand:
            let assessment = RiskDetector().assess(trimmed, policy: state.settings.confirmationPolicy)
            if assessment.requiresConfirmation {
                onShellConfirm(trimmed, assessment)
            } else {
                controller.run(trimmed)
            }
            hint = nil
        case .naturalLanguage:
            if state.aiMode == .off {
                hint = "AI 未启用，请输入 shell 命令"
            } else {
                onNaturalLanguage(trimmed)
                hint = nil
            }
        case .notCommandNoAi:
            hint = "AI 未启用，请输入 shell 命令"
        }
        state.inputDraft = ""
        historyIndex = nil
    }

    private func pushHistory(_ entry: String) {
        if history.last == entry { return }
        history.append(entry)
        if history.count > 50 { history.removeFirst(history.count - 50) }
    }

    private func currentPathDirs() -> [String] {
        guard let path = ProcessInfo.processInfo.environment["PATH"] else { return [] }
        return path.split(separator: ":").map(String.init)
    }
}
