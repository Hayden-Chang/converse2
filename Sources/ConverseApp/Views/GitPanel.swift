import SwiftUI
import ConverseCore

struct GitPanel: View {
    let repoPath: String

    @State private var status: GitStatus?
    @State private var selectedFile: String?
    @State private var diff: String = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
            header
            content
        }
        .padding(Theme.Spacing.s7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bgApp)
        .onAppear { reload() }
    }

    private var reader: GitReader { GitReader(repoPath: repoPath) }

    private var header: some View {
        HStack(spacing: Theme.Spacing.s4) {
            Image(systemName: "arrow.triangle.branch")
                .foregroundStyle(Theme.primary)
                .font(.system(size: 12, weight: .semibold))
            Text(status?.branch ?? "—")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
            Button { reload() } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(Theme.textSecondary)
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .disabled(repoPath.isEmpty)
        }
    }

    @ViewBuilder
    private var content: some View {
        if repoPath.isEmpty || !reader.isRepo() {
            Text("该文件夹不是 Git 仓库")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textTertiary)
            Spacer()
        } else if let err = error {
            VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
                Text("读取失败：\(err)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.danger)
                Button("重试") { reload() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.primary)
                    .font(.system(size: 12))
            }
            Spacer()
        } else if let st = status {
            if st.changes.isEmpty {
                Text("工作区干净，无改动")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
            } else {
                fileList(st)
                diffView
            }
        }
    }

    private func fileList(_ st: GitStatus) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                ForEach(st.changes) { c in
                    fileRow(c)
                }
            }
        }
    }

    private func fileRow(_ c: GitFileChange) -> some View {
        HStack(spacing: Theme.Spacing.s4) {
            Text(badgeText(c))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .padding(.horizontal, Theme.Spacing.s3)
                .padding(.vertical, 1)
                .background(badgeColor(c).opacity(0.15),
                            in: RoundedRectangle(cornerRadius: Theme.Radius.xs))
                .foregroundStyle(badgeColor(c))
            Text(c.path)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.s4)
        .padding(.vertical, Theme.Spacing.s3)
        .background(selectedFile == c.path ? Theme.bgMuted : .clear,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
        .contentShape(Rectangle())
        .onTapGesture {
            selectedFile = c.path
            loadDiff(c.path)
        }
    }

    @ViewBuilder
    private var diffView: some View {
        if let sel = selectedFile {
            ScrollView {
                Text(diff.isEmpty ? "（\(sel) 无 unstaged diff）" : diff)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .textSelection(.enabled)
            }
            .padding(Theme.Spacing.s4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bgSubtle, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
        } else {
            Text("选择文件查看 diff")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bgSubtle, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
        }
    }

    private func badgeText(_ c: GitFileChange) -> String {
        if c.isUntracked { return "??" }
        if c.stagedStatus != " " { return String(c.stagedStatus) }
        return String(c.worktreeStatus)
    }

    private func badgeColor(_ c: GitFileChange) -> Color {
        if c.isUntracked { return Theme.textTertiary }
        let s = c.worktreeStatus != " " ? c.worktreeStatus : c.stagedStatus
        switch s {
        case "A": return Theme.success
        case "D": return Theme.danger
        case "M": return Theme.warning
        default: return Theme.textSecondary
        }
    }

    private func reload() {
        diff = ""
        selectedFile = nil
        guard !repoPath.isEmpty, reader.isRepo() else { status = nil; error = nil; return }
        do {
            status = try reader.status()
            error = nil
        } catch {
            self.error = "\(error)"
            status = nil
        }
    }

    private func loadDiff(_ path: String) {
        do {
            diff = try reader.diff(forFile: path)
        } catch {
            diff = "读取 diff 失败：\(error)"
        }
    }
}
