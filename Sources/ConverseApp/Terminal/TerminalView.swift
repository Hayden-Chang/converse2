import SwiftUI
import SwiftTerm
import AppKit

struct SwiftTerminalView: NSViewRepresentable {
    let directory: String
    var onProcessTerminated: ((Int32?) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onProcessTerminated: onProcessTerminated)
    }

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let view = LocalProcessTerminalView(frame: .zero)
        view.processDelegate = context.coordinator
        applyAppearance(to: view)
        context.coordinator.terminalView = view
        let session = TerminalSession(directory: directory)
        session.terminalView = view
        view.startProcess(
            executable: session.executable,
            args: session.args,
            environment: session.environment,
            execName: session.execName,
            currentDirectory: session.directory
        )
        return view
    }

    func updateNSView(_ view: LocalProcessTerminalView, context: Context) {
        applyAppearance(to: view)
        context.coordinator.onProcessTerminated = onProcessTerminated
    }

    private func applyAppearance(to view: LocalProcessTerminalView) {
        view.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        view.nativeBackgroundColor = NSColor(Theme.bgSubtle)
        view.nativeForegroundColor = NSColor(Theme.textPrimary)
    }

    final class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var onProcessTerminated: ((Int32?) -> Void)?
        weak var terminalView: LocalProcessTerminalView?

        init(onProcessTerminated: ((Int32?) -> Void)?) {
            self.onProcessTerminated = onProcessTerminated
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        func processTerminated(source: TerminalView, exitCode: Int32?) {
            onProcessTerminated?(exitCode)
        }
    }
}
