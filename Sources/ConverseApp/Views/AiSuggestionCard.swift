import SwiftUI
import ConverseCore

struct AiSuggestionCard: View {
    let suggestion: AiCommandSuggestion
    let controller: TerminalController
    var onDismiss: () -> Void
    var onEdit: (String) -> Void

    @State private var editing: Bool = false
    @State private var editedText: String = ""
    @State private var showConfirm: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
            HStack(spacing: Theme.Spacing.s3) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.primary)
                    .font(.system(size: 12))
                Text("AI 建议")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                riskBadge
            }
            if let explanation = suggestion.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            if editing {
                TextField("编辑命令", text: $editedText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .lineLimit(1...4)
                    .padding(Theme.Spacing.s4)
                    .background(Theme.bgSubtle, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
                HStack(spacing: Theme.Spacing.s3) {
                    Button("重新判定") {
                        let cmd = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cmd.isEmpty else { return }
                        onEdit(cmd)
                        editing = false
                    }
                    .font(.system(size: 12))
                    Button("取消编辑") { editing = false }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                }
            } else {
                Text(suggestion.command)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.s4)
                    .background(Theme.bgSubtle, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
                    .textSelection(.enabled)
            }
            if !suggestion.impactScope.isEmpty {
                Text("影响范围：\(suggestion.impactScope)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            HStack(spacing: Theme.Spacing.s3) {
                Button {
                    if suggestion.requiresConfirmation &&
                        (suggestion.riskLevel == .high || suggestion.riskLevel == .critical) {
                        showConfirm = true
                    } else {
                        controller.run(suggestion.command)
                        onDismiss()
                    }
                } label: {
                    Label("执行", systemImage: "play.fill")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)

                Button("编辑") {
                    editedText = suggestion.command
                    editing = true
                }
                .font(.system(size: 12))

                Spacer()

                Button("取消") { onDismiss() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
            }
        }
        .padding(Theme.Spacing.s6)
        .background(Theme.bgSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).stroke(Theme.border))
        .padding(.horizontal, Theme.Spacing.s6)
        .padding(.vertical, Theme.Spacing.s4)
        .sheet(isPresented: $showConfirm) {
            RiskConfirmDialog(
                command: suggestion.command,
                level: suggestion.riskLevel,
                impactScope: suggestion.impactScope,
                onConfirm: {
                    controller.run(suggestion.command)
                    onDismiss()
                },
                onCancel: { showConfirm = false }
            )
        }
    }

    private var riskBadge: some View {
        let (color, bg) = badgeColors(suggestion.riskLevel)
        return Text("风险：\(suggestion.riskLevel.label)")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.s3)
            .padding(.vertical, Theme.Spacing.xs)
            .background(bg, in: Capsule())
    }

    private func badgeColors(_ level: RiskLevel) -> (Color, Color) {
        switch level {
        case .low: (Theme.textSecondary, Theme.bgMuted)
        case .medium: (Theme.warning, Theme.warning.opacity(0.14))
        case .high: (Theme.danger, Theme.dangerSoft)
        case .critical: (.white, Theme.danger)
        }
    }
}

struct RiskConfirmDialog: View {
    let command: String
    let level: RiskLevel
    let impactScope: String
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @State private var seconds: Int = 5
    @State private var timer: Timer?
    @FocusState private var cancelFocused: Bool

    private var isCritical: Bool { level == .critical }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
            HStack(spacing: Theme.Spacing.s4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(isCritical ? Theme.danger : Theme.warning)
                    .font(.system(size: 16))
                Text(isCritical ? "极高风险确认" : "高风险确认")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            if !impactScope.isEmpty {
                Text("影响范围：\(impactScope)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(command)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.s4)
                .background(Theme.dangerSoft, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
                .textSelection(.enabled)
            if isCritical && seconds > 0 {
                Text("极高风险，请 \(seconds) 秒后再确认")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.danger)
            }
            HStack(spacing: Theme.Spacing.s4) {
                Spacer()
                Button("取消", action: onCancel)
                    .focused($cancelFocused)
                    .keyboardShortcut(.cancelAction)
                Button("确认执行", action: onConfirm)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.danger)
                    .disabled(isCritical && seconds > 0)
            }
        }
        .padding(Theme.Spacing.s8)
        .frame(width: 460)
        .onAppear {
            if isCritical {
                cancelFocused = true
                startCountdown()
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    private func startCountdown() {
        seconds = 5
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if seconds > 1 {
                seconds -= 1
            } else {
                seconds = 0
                t.invalidate()
            }
        }
    }
}
