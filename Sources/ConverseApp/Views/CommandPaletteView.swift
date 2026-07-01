import SwiftUI
import ConverseCore

struct CommandPaletteView: View {
    @EnvironmentObject var state: AppState
    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var searchFocused: Bool

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
                HStack(spacing: Theme.Spacing.s4) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.textTertiary)
                    TextField("搜索文件夹或会话…", text: $query)
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
                if results.isEmpty {
                    Text("无结果").font(.system(size: 12)).foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(results.enumerated()), id: \.element.id) { idx, item in
                                row(item, selected: idx == selectedIndex)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedIndex = idx; activateSelected() }
                                    .onHover { if $0 { selectedIndex = idx } }
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
    }

    private var results: [Item] {
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

    private func row(_ item: Item, selected: Bool) -> some View {
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

    private func moveSelection(_ delta: Int) {
        guard !results.isEmpty else { return }
        selectedIndex = min(max(0, selectedIndex + delta), results.count - 1)
    }

    private func activateSelected() {
        guard results.indices.contains(selectedIndex) else { return }
        let item = results[selectedIndex]
        if item.kind == .session, let key = item.sessionKey {
            if let fid = item.folderId { state.selectedFolderID = fid }
            state.selectedSessionID = key
        } else if let fid = item.folderId {
            state.selectedFolderID = fid
        }
        close()
    }

    private func close() { state.showCommandPalette = false }
}
