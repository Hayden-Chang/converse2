import SwiftUI

@main
struct ConverseApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .frame(minWidth: 1000, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)

        // 设置窗口（路由，见任务 7.3）
        Settings {
            SettingsView()
                .environmentObject(state)
        }
    }
}
