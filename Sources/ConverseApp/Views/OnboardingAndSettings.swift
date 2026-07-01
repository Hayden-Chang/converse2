import SwiftUI
import ConverseCore

/// 首次启动 4 步向导占位（任务 7.4 细化）。
struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.s9) {
            Text("Converse").font(.system(size: 28, weight: .semibold))
            Text("真实终端为底座，对话式命令层 + 文件夹会话组织 + Git 审查")
                .multilineTextAlignment(.center).foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: 420)
            Button("开始使用") { onContinue() }
                .buttonStyle(.borderedProminent).controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgApp)
    }
}

/// 设置页占位（任务 7.3：AI 模式、API 配置、shell、tmux namespace）。
struct SettingsView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        TabView {
            Form {
                Picker("AI 模式", selection: $state.aiMode) {
                    ForEach(AiMode.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                TextField("API Base URL", text: .constant("https://api.deepseek.com"))
                TextField("模型", text: .constant("deepseek-v4-flash"))
                TextField("强模型", text: .constant("deepseek-v4-flash"))
            }
            .padding(Theme.Spacing.s9)
            .tabItem { Label("AI", systemImage: "cpu") }

            Form {
                TextField("默认 Shell", text: .constant("/bin/zsh"))
                TextField("tmux 命名空间", text: .constant("converse"))
            }
            .padding(Theme.Spacing.s9)
            .tabItem { Label("终端", systemImage: "terminal") }
        }
        .frame(width: 460, height: 300)
    }
}
