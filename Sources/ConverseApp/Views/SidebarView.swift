import SwiftUI
import AppKit
import ConverseCore

struct SidebarView: View {
    @EnvironmentObject var state: AppState
    @State private var newSessionFolder: Folder?
    @State private var newSessionName: String = ""
    @State private var missingPrompt: SessionRecord?
    @State private var deleteFolderPrompt: Folder?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().background(Theme.border)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(state.folders, id: \.id) { folder in
                        folderSection(folder)
                    }
                    if state.folders.isEmpty {
                        Text("点 + 添加一个文件夹").font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                            .padding(Theme.Spacing.s9)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .background(Theme.bgSurface)
        .sheet(item: $newSessionFolder) { folder in
            newSessionSheet(folder)
        }
        .onAppear { checkMissing() }
        .onChange(of: state.selectedSessionID) { _ in checkMissing() }
        .alert(
            "会话已丢失（tmux 不存在）",
            isPresented: Binding(get: { missingPrompt != nil },
                                 set: { if !$0 { missingPrompt = nil } })
        ) {
            Button("重新创建") {
                if let s = missingPrompt { state.recreateSession(s) }
                missingPrompt = nil
            }
            Button("移除记录", role: .destructive) {
                if let s = missingPrompt { state.forceCloseSession(s) }
                missingPrompt = nil
            }
            Button("取消", role: .cancel) { missingPrompt = nil }
        } message: {
            Text("该会话的 tmux 已不存在（可能因机器重启或 tmux server 退出）。是否重新创建？")
        }
        .confirmationDialog(
            "该工作区有运行中的会话，仍要移除？",
            isPresented: Binding(get: { deleteFolderPrompt != nil },
                                 set: { if !$0 { deleteFolderPrompt = nil } }),
            presenting: deleteFolderPrompt
        ) { folder in
            Button("移除（关闭会话）", role: .destructive) {
                state.deleteFolder(folder)
                deleteFolderPrompt = nil
            }
            Button("取消", role: .cancel) { deleteFolderPrompt = nil }
        } message: { _ in
            Text("相关会话将被关闭，磁盘目录不受影响。")
        }
    }

    private func checkMissing() {
        guard let s = state.selectedSession() else { missingPrompt = nil; return }
        if state.status(for: s) == .missing { missingPrompt = s } else { missingPrompt = nil }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.s3) {
            Image(systemName: "folder").font(.system(size: 11)).foregroundStyle(Theme.textTertiary)
            Text("文件夹").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.textTertiary)
            Spacer()
            Button { pickFolder() } label: {
                Image(systemName: "plus").font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("添加文件夹")
        }
        .padding(.horizontal, Theme.Spacing.s7).padding(.vertical, Theme.Spacing.s4)
    }

    private func folderSection(_ folder: Folder) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Theme.Spacing.s4) {
                Image(systemName: "folder.fill").font(.system(size: 11)).foregroundStyle(Theme.primary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(folder.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                    Text(folder.diskPath).font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary).lineLimit(1).truncationMode(.middle)
                }
                Spacer()
                Button { newSessionFolder = folder } label: {
                    Image(systemName: "square.and.pencil").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }.buttonStyle(.plain).help("新建会话")
                Button {
                    if state.hasRunningSessions(in: folder) {
                        deleteFolderPrompt = folder
                    } else {
                        state.deleteFolder(folder)
                    }
                } label: {
                    Image(systemName: "trash").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }.buttonStyle(.plain).help("删除文件夹")
            }
            .padding(.horizontal, Theme.Spacing.s7).padding(.vertical, Theme.Spacing.s4)
            ForEach(state.sessions(in: folder), id: \.id) { s in
                sessionRow(s)
            }
        }
    }

    private func sessionRow(_ session: SessionRecord) -> some View {
        let sid = state.tmuxShortID(for: session)
        let st = state.status(for: session)
        let isSelected = state.selectedSessionID == sid
        return HStack(spacing: Theme.Spacing.s4) {
            Circle().fill(st == .running ? Theme.success : Theme.danger).frame(width: 6, height: 6)
            Text(session.name).font(.system(size: 12)).foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
            Spacer()
            Text(st.label).font(.system(size: 10, weight: .medium))
                .padding(.horizontal, Theme.Spacing.s3).padding(.vertical, 1)
                .background(st == .running ? Theme.successSoft : Theme.dangerSoft, in: RoundedRectangle(cornerRadius: Theme.Radius.xs))
                .foregroundStyle(st == .running ? Theme.success : Theme.danger)
            Button { state.closeSession(session) } label: {
                Image(systemName: "xmark").font(.system(size: 9, weight: .semibold)).foregroundStyle(Theme.textTertiary)
            }.buttonStyle(.plain).help("关闭会话")
        }
        .padding(.horizontal, Theme.Spacing.s7).padding(.vertical, Theme.Spacing.s3)
        .padding(.leading, Theme.Spacing.s6)
        .background(isSelected ? Theme.bgMuted : .clear, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
        .contentShape(Rectangle())
        .onTapGesture {
            state.selectedFolderID = session.folderId
            state.selectedSessionID = sid
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "添加"
        if panel.runModal() == .OK, let url = panel.url {
            state.addFolder(name: url.lastPathComponent, diskPath: url.path)
        }
    }

    private func newSessionSheet(_ folder: Folder) -> some View {
        VStack(spacing: Theme.Spacing.s7) {
            Text("新建会话").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            TextField("会话名称", text: $newSessionName).textFieldStyle(.roundedBorder)
            HStack {
                Button("取消") { newSessionFolder = nil; newSessionName = "" }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("创建") {
                    let name = newSessionName.trimmingCharacters(in: .whitespaces)
                    state.createSession(in: folder, name: name.isEmpty ? "新会话" : name)
                    newSessionName = ""
                    newSessionFolder = nil
                }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.Spacing.s9).frame(width: 320)
    }
}
