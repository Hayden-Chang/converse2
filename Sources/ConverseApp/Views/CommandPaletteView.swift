import SwiftUI
import ConverseCore

enum PaletteTab { case sessions, history }

struct CommandPaletteView: View {
    @EnvironmentObject var state: AppState
    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @State private var tab: PaletteTab
    @FocusState private var searchFocused: Bool

    init(initialTab: PaletteTab = .sessions) {
        _tab = State(initialValue: initialTab)
    }

    struct Item: Identifiable, Hashable {
        enum Kind: Hashable { case folder, session }
        let id: String
        let name: String
        let parent: String
        let kind: Kind
        let folderId: Int64?
        let sessionKey: String?
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
                .onTapGesture { close() }
            VStack(spacing: 0) {
                HStack(spacing: Theme.Spacing.s8) {
                    tabBarButton(.sessions, label: "会话")
                    tabBarButton(.history, label: "历史")
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.s7)
                .padding(.top, Theme.Spacing.s4)
                .padding(.bottom, Theme.Spacing.s3)
                Divider().background(Theme.border)
                HStack(spacing: Theme.Spacing.s4) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.textTertiary)
                    TextField(tab == .sessions ? "搜索文件夹或会话…" : "搜索历史命令…", text: $query)
                        .focused($searchFocused)
                        .submitLabel(.go)
                        .onSubmit { activateSelected() }
                        .onChange(of: query) { _ in selectedIndex = 0 }
                    Button { close() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textTertiary)
                    }.buttonStyle(.plain).keyboardShortcut(.escape, modifiers: [])
                }
                .padding(.horizontal, Theme.Spacing.s7).padding(.vertical, Theme.Spacing.s6)
                Divider().background(Theme.border)
                if currentCount == 0 {
                    Text(tab == .history ? "无历史命令" : "无结果")
                        .font(.system(size: 12)).foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if tab == .sessions {
                                ForEach(Array(sessionResults.enumerated()), id: \.element.id) { idx, item in
                                    sessionRow(item, selected: idx == selectedIndex)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedIndex = idx; activateSelected() }
                                        .onHover { if $0 { selectedIndex = idx } }
                                }
                            } else {
                                ForEach(Array(historyResults.enumerated()), id: \.offset) { idx, run in
                                    historyRow(run, selected: idx == selectedIndex)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedIndex = idx; activateSelected() }
                                        .onHover { if $0 { selectedIndex = idx } }
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: 560, height: 360)
            .background(Theme.bgSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.xl))
            .shadow(color: .black.opacity(0.15), radius: 24, y: 8)
            .overlay {
                Button("") { moveSelection(-1) }.keyboardShortcut(.upArrow, modifiers: []).hidden()
                Button("") { moveSelection(1) }.keyboardShortcut(.downArrow, modifiers: []).hidden()
            }
        }
        .onAppear { searchFocused = true }
        .onChange(of: tab) { _ in query = ""; selectedIndex = 0 }
        .onChange(of: state.paletteInitialTab) { newTab in tab = newTab }
    }

    private func tabBarButton(_ t: PaletteTab, label: String) -> some View {
        let isOn = tab == t
        return Button {
            tab = t
        } label: {
            VStack(spacing: Theme.Spacing.s3) {
                Text(label)
                    .font(.system(size: 13, weight: isOn ? .semibold : .regular))
                    .foregroundStyle(isOn ? Theme.primary : Theme.textTertiary)
                Rectangle()
                    .fill(isOn ? Theme.primary : Color.clear)
                    .frame(height: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var sessionResults: [Item] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        var items: [Item] = []
        for folder in state.folders {
            let fid = folder.id
            if q.isEmpty || folder.name.lowercased().contains(q) {
                items.append(Item(id: "f:\(fid ?? -1)", name: folder.name,
                                  parent: folder.diskPath, kind: .folder,
                                  folderId: fid, sessionKey: nil))
            }
            for s in state.sessions(in: folder) {
                if q.isEmpty || s.name.lowercased().contains(q) {
                    items.append(Item(id: "s:\(s.id ?? -1)", name: s.name,
                                      parent: folder.name, kind: .session,
                                      folderId: fid, sessionKey: state.tmuxShortID(for: s)))
                }
            }
        }
        return items
    }

    private var sessionNames: [Int64: String] {
        var m: [Int64: String] = [:]
        for f in state.folders {
            for s in state.sessions(in: f) {
                if let id = s.id { m[id] = s.name }
            }
        }
        return m
    }

    private var historyResults: [CommandRun] {
        let svc = HistoryService(db: state.db)
        let kw = query.trimmingCharacters(in: .whitespaces)
        if kw.isEmpty {
            guard let sid = state.selectedSession()?.id else { return [] }
            return (try? svc.recentCommands(sessionId: sid, limit: 30)) ?? []
        }
        return (try? svc.searchCommands(sessionId: nil, keyword: kw, limit: 30)) ?? []
    }

    private var currentCount: Int {
        tab == .sessions ? sessionResults.count : historyResults.count
    }

    private func sessionRow(_ item: Item, selected: Bool) -> some View {
        HStack(spacing: Theme.Spacing.s6) {
            Image(systemName: item.kind == .folder ? "folder.fill" : "terminal")
                .foregroundStyle(item.kind == .folder ? Theme.primary : Theme.textSecondary)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.system(size: 13)).foregroundStyle(Theme.textPrimary)
                Text(item.parent).font(.system(size: 11)).foregroundStyle(Theme.textTertiary)
                    .lineLimit(1).truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.s7).padding(.vertical, Theme.Spacing.s4)
        .background(selected ? Theme.primarySoft : Color.clear)
    }

    private func historyRow(_ run: CommandRun, selected: Bool) -> some View {
        HStack(spacing: Theme.Spacing.s6) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(Theme.textTertiary).frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(run.commandText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: Theme.Spacing.s3) {
                    if let name = sessionNames[run.sessionId] { Text(name) }
                    Text(RelativeDateTimeFormatter()
                            .localizedString(for: run.startedAt, relativeTo: Date()))
                }
                .font(.system(size: 11)).foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.s7).padding(.vertical, Theme.Spacing.s4)
        .background(selected ? Theme.primarySoft : Color.clear)
    }

    private func moveSelection(_ delta: Int) {
        guard currentCount > 0 else { return }
        selectedIndex = min(max(0, selectedIndex + delta), currentCount - 1)
    }

    private func activateSelected() {
        switch tab {
        case .sessions:
            guard sessionResults.indices.contains(selectedIndex) else { return }
            let item = sessionResults[selectedIndex]
            if item.kind == .session, let key = item.sessionKey {
                if let fid = item.folderId { state.selectedFolderID = fid }
                state.selectedSessionID = key
            } else if let fid = item.folderId {
                state.selectedFolderID = fid
            }
            close()
        case .history:
            guard historyResults.indices.contains(selectedIndex) else { return }
            let cmd = historyResults[selectedIndex].commandText
            close()
            state.fillInput(cmd)
        }
    }

    private func close() { state.showCommandPalette = false }
}
