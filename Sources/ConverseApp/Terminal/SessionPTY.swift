import Foundation
import SwiftTerm

final class TerminalSession {
    enum Mode { case shell, tmux }

    let mode: Mode
    let directory: String
    let shell: String
    let tmuxSessionID: String?
    weak var terminalView: LocalProcessTerminalView?

    init(directory: String, shell: String? = nil) {
        self.mode = .shell
        self.directory = directory
        self.shell = shell ?? ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        self.tmuxSessionID = nil
    }

    init(tmuxSessionID: String, directory: String) {
        self.mode = .tmux
        self.directory = directory
        self.shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        self.tmuxSessionID = tmuxSessionID
    }

    var executable: String {
        switch mode {
        case .shell: return shell
        case .tmux:  return TmuxManager.resolvedBinPath() ?? "/usr/local/bin/tmux"
        }
    }

    var args: [String] {
        switch mode {
        case .shell: return []
        case .tmux:  return ["attach", "-t", TmuxManager.sessionName(for: tmuxSessionID ?? "")]
        }
    }

    var environment: [String] {
        let env = ProcessInfo.processInfo.environment
        switch mode {
        case .shell:
            return env.map { "\($0.key)=\($0.value)" }
        case .tmux:
            return env
                .filter { $0.key != "TMUX" && $0.key != "TMUX_PANE" }
                .map { "\($0.key)=\($0.value)" }
        }
    }

    var execName: String {
        switch mode {
        case .shell: return (shell as NSString).lastPathComponent
        case .tmux:  return "tmux"
        }
    }

    func sendInterrupt() {
        terminalView?.send([0x03])
    }
}
