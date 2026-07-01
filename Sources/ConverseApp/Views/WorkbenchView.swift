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
                OnboardingView(onContinue: {
                    state.addSampleData()
                    state.hasCompletedOnboarding = true
                })
            }
            if state.showSettings { Color.clear }
        }
        .background(Theme.bgApp)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    var body: some View {
        HStack(spacing: Theme.Spacing.s7) {
            Text("Converse").font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            Button {
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
    }
}

struct WorkspaceBar: View {
    var body: some View {
        Theme.bgSurface
    }
}

struct SessionSidebar: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(state.folders) { folder in
                Text(folder.name).font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, Theme.Spacing.s7).padding(.top, Theme.Spacing.s7)
                ForEach(folder.sessions) { s in
                    HStack {
                        Text(s.name).foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(s.status.label)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, Theme.Spacing.s3).padding(.vertical, 1)
                            .background(s.status == .running ? Theme.successSoft : Theme.dangerSoft,
                                        in: RoundedRectangle(cornerRadius: Theme.Radius.xs))
                            .foregroundStyle(s.status == .running ? Theme.success : Theme.danger)
                    }
                    .padding(.horizontal, Theme.Spacing.s7).padding(.vertical, Theme.Spacing.s4)
                    .background(state.selectedSessionID == s.id ? Theme.bgMuted : .clear,
                                in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
                }
            }
            Spacer()
        }
        .background(Theme.bgSurface)
    }
}

struct MainColumn: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.bgSubtle
                Text("终端区").foregroundStyle(Theme.textTertiary)
            }
            Divider().background(Theme.border)
            HStack(spacing: Theme.Spacing.s6) {
                Text("说点什么或打个命令…").foregroundStyle(Theme.textTertiary)
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.s9).frame(height: 48)
            .background(Theme.bgSurface)
        }
        .background(Theme.bgSurface)
    }
}

struct ReviewPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
            Text("Git 审查").font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("只读面板占位").font(.system(size: 12)).foregroundStyle(Theme.textTertiary)
            Spacer()
        }
        .padding(Theme.Spacing.s9).background(Theme.bgApp)
    }
}
