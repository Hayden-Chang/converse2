import Foundation
import SwiftTerm

final class TerminalSession {
    let directory: String
    let shell: String
    weak var terminalView: LocalProcessTerminalView?

    init(directory: String, shell: String? = nil) {
        self.directory = directory
        self.shell = shell ?? ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    }

    var executable: String { shell }
    var args: [String] { [] }
    var environment: [String] {
        ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
    }
    var execName: String {
        (shell as NSString).lastPathComponent
    }

    func sendInterrupt() {
        terminalView?.send([0x03])
    }
}
