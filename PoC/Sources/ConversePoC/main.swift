import AppKit
import SwiftTerm

// Minimal PoC: prove SwiftTerm + posix pty renders a real shell (vim/top/less/ANSI).
// LocalProcessTerminalView internally forks a pty and runs the given executable.
final class PoCDelegate: NSObject, LocalProcessTerminalViewDelegate {
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
    func send(source: LocalProcessTerminalView, data: Data) {}
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = PoCDelegate()

// Real architecture: SwiftTerm's pty execs `tmux attach -t <session>` so sessions persist.
// If CONVERSE_TMUX_SESSION is set, attach to that tmux session; otherwise run a bare shell.
let env = ProcessInfo.processInfo.environment
let tv = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 560))
tv.processDelegate = delegate
var procEnv = env.map { "\($0.key)=\($0.value)" }
if let sid = env["CONVERSE_TMUX_SESSION"], !sid.isEmpty {
    tv.feed(text: "Converse PoC — attaching SwiftTerm pty to tmux: \(sid)\n")
    procEnv.removeAll { $0.hasPrefix("TMUX=") || $0.hasPrefix("TMUX_PANE=") }
    tv.startProcess(executable: "/usr/local/bin/tmux",
                    args: ["attach", "-t", sid],
                    environment: procEnv, execName: "tmux")
} else {
    let shell = env["SHELL"] ?? "/bin/zsh"
    tv.feed(text: "Converse PoC — SwiftTerm + posix pty (bare shell). Try: ls, vim, top\n")
    tv.startProcess(executable: shell, args: [], environment: procEnv,
                    execName: (shell as NSString).lastPathComponent)
}

let win = NSWindow(contentRect: tv.frame,
                   styleMask: [.titled, .closable, .resizable],
                   backing: .buffered, defer: false)
win.title = "Converse PoC"
win.contentView = tv
win.makeKeyAndOrderFront(nil)
win.center()

app.run()
