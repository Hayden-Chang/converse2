import Foundation
import SwiftTerm

final class TerminalController: ObservableObject {
    weak var terminalView: LocalProcessTerminalView?

    func run(_ command: String) {
        guard let view = terminalView else { return }
        view.send(txt: command + "\n")
    }

    func interrupt() {
        guard let view = terminalView else { return }
        view.send([0x03])
    }
}
