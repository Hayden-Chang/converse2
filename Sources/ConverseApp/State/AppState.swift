import SwiftUI
import ConverseCore

/// 顶层应用状态：路由（主窗口/设置/onboarding）+ AI 模式 + 选中的文件夹/会话。
@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published var showSettings = false
    @Published var showCommandPalette = false   // ⌘K
    @Published var aiMode: AiMode = .suggest

    @Published var folders: [FolderItem] = []
    @Published var selectedFolderID: FolderItem.ID?
    @Published var selectedSessionID: SessionItem.ID?

    func addSampleData() {
        let f = FolderItem(name: "公司官网", sessions: [
            SessionItem(name: "安装依赖", status: .running),
            SessionItem(name: "跑构建", status: .missing),
        ])
        folders = [f]
        selectedFolderID = f.id
        selectedSessionID = f.sessions.first?.id
    }
}

/// 左栏文件夹与它的会话（脚手架占位类型；正式数据模型见任务 4）。
struct FolderItem: Identifiable {
    let id = UUID()
    let name: String
    var sessions: [SessionItem]
}

struct SessionItem: Identifiable {
    let id = UUID()
    let name: String
    let status: SessionStatus
}
