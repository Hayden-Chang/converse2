import Foundation
import SwiftTerm

final class TerminalController: ObservableObject {
    weak var terminalView: LocalProcessTerminalView?

    @Published var terminalMode: Bool = false
    @Published var awaitingPassword: Bool = false

    static let tuiCommands: Set<String> = [
        "vim", "vi", "nano", "emacs", "top", "htop", "btop",
        "less", "more", "man", "most", "python", "python2", "python3",
        "node", "irb", "pry", "lua", "bc", "psql", "mysql", "sqlite3",
        "ssh", "telnet", "tmux", "screen"
    ]

    func run(_ command: String) {
        notifyCommandSent(command)
        guard let view = terminalView else { return }
        view.send(txt: command + "\n")
    }

    func interrupt() {
        guard let view = terminalView else { return }
        view.send([0x03])
    }

    func notifyCommandSent(_ command: String) {
        awaitingPassword = false
        let tokens = command
            .split(separator: " ", omittingEmptySubsequences: true)
            .map { String($0) }
        guard let first = tokens.first else { return }
        let resolved = Self.basename(first).lowercased()
        if resolved == "sudo" {
            awaitingPassword = true
            if let second = tokens.dropFirst().first {
                let s = Self.basename(second).lowercased()
                if Self.tuiCommands.contains(s) { terminalMode = true }
            }
        } else if Self.tuiCommands.contains(resolved) {
            terminalMode = true
        }
    }

    func exitTerminalMode() {
        terminalMode = false
    }

    func clearPasswordState() {
        awaitingPassword = false
    }

    private static func basename(_ token: String) -> String {
        if let last = token.split(separator: "/").last { return String(last) }
        return token
    }
}
