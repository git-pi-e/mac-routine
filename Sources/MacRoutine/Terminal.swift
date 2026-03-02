import Foundation
import Darwin

struct T {
    static let reset   = "\u{001B}[0m"
    static let bold    = "\u{001B}[1m"
    static let dim     = "\u{001B}[2m"
    static let cyan    = "\u{001B}[36m"
    static let green   = "\u{001B}[32m"
    static let yellow  = "\u{001B}[33m"
    static let red     = "\u{001B}[31m"
    static let blue    = "\u{001B}[34m"
    static let white   = "\u{001B}[97m"
    static let bgDark  = "\u{001B}[48;5;234m"

    static func out(_ s: String, terminator: String = "\n") {
        print(s, terminator: terminator)
        fflush(stdout)
    }

    static func clearLine() { out("\r\u{001B}[K", terminator: "") }
    static func up(_ n: Int = 1) { out("\u{001B}[\(n)A", terminator: "") }
    static func clearDown() { out("\u{001B}[J", terminator: "") }
    static func hideCursor() { out("\u{001B}[?25l", terminator: "") }
    static func showCursor() { out("\u{001B}[?25h", terminator: "") }

    private static var original = termios()

    static func rawMode(_ on: Bool) {
        if on {
            tcgetattr(STDIN_FILENO, &original)
            var raw = original
            raw.c_lflag &= ~UInt(ICANON | ECHO)
            withUnsafeMutableBytes(of: &raw.c_cc) { ptr in
                ptr[Int(VMIN)] = 1; ptr[Int(VTIME)] = 0
            }
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        } else {
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
        }
    }

    enum Key { case up, down, enter, space, escape, char(Character), backspace, unknown }

    static func readKey() -> Key {
        var c: UInt8 = 0
        read(STDIN_FILENO, &c, 1)
        guard c != 27 else {
            var seq = [UInt8](repeating: 0, count: 2)
            var fds = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
            guard poll(&fds, 1, 50) > 0 else { return .escape }
            read(STDIN_FILENO, &seq[0], 1)
            read(STDIN_FILENO, &seq[1], 1)
            if seq[0] == 91 {
                switch seq[1] {
                case 65: return .up
                case 66: return .down
                default: return .unknown
                }
            }
            return .unknown
        }
        switch c {
        case 13, 10: return .enter
        case 32:     return .space
        case 127:    return .backspace
        default:     return .char(Character(UnicodeScalar(c)))
        }
    }

    static func box(title: String, width: Int = 54) {
        let pad = String(repeating: " ", count: max(0, (width - title.count - 2) / 2))
        let line = String(repeating: "─", count: width)
        out("\(cyan)╭\(line)╮\(reset)")
        out("\(cyan)│\(reset)\(bold)\(pad) \(title) \(pad)\(reset)\(cyan)│\(reset)")
        out("\(cyan)╰\(line)╯\(reset)")
    }

    static func section(_ title: String) {
        out("\n\(bold)\(cyan)  \(title)\(reset)")
        out("\(dim)  \(String(repeating: "─", count: 50))\(reset)")
    }

    static func label(_ text: String) { out("\(dim)  \(text)\(reset)") }

    static func success(_ text: String) { out("  \(green)✓\(reset)  \(text)") }
    static func info(_ text: String) { out("  \(cyan)·\(reset)  \(text)") }
    static func warn(_ text: String) { out("  \(yellow)!\(reset)  \(text)") }

    static func prompt(_ text: String, default def: String? = nil) -> String {
        let suffix = def.map { " (\(dim)\($0)\(reset))" } ?? ""
        out("  \(bold)\(text)\(reset)\(suffix)\(cyan) ›\(reset) ", terminator: "")
        return readLine(strippingNewline: true)?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    static func spinner(label: String, _ work: () -> Void) {
        let frames = ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]
        var i = 0
        var done = false
        let thread = Thread {
            while !done {
                T.clearLine()
                T.out("  \(T.cyan)\(frames[i % 10])\(T.reset)  \(label)", terminator: "")
                i += 1
                Thread.sleep(forTimeInterval: 0.08)
            }
        }
        hideCursor()
        thread.start()
        work()
        done = true
        Thread.sleep(forTimeInterval: 0.09)
        showCursor()
        clearLine()
    }

    static func multiSelect<T>(
        title: String,
        items: [T],
        display: (T) -> String,
        preselected: Set<Int> = []
    ) -> Set<Int> {
        var selected = preselected
        var cursor = 0
        hideCursor()
        rawMode(true)
        defer { rawMode(false); showCursor() }

        func draw() {
            up(items.count + 2)
            clearDown()
            out("\(dim)  Space to select · Enter to confirm\(reset)")
            out("")
            for (i, item) in items.enumerated() {
                let isCursor   = i == cursor
                let isSelected = selected.contains(i)
                let dot        = isSelected ? "\(cyan)◉\(reset)" : "\(dim)○\(reset)"
                let arrow      = isCursor   ? "\(cyan)▸\(reset)" : " "
                let label      = isCursor   ? "\(bold)\(display(item))\(reset)" : display(item)
                out("  \(arrow) \(dot)  \(label)")
            }
        }

        out(String(repeating: "\n", count: items.count + 2))
        draw()

        while true {
            switch readKey() {
            case .up:    cursor = max(0, cursor - 1); draw()
            case .down:  cursor = min(items.count - 1, cursor + 1); draw()
            case .space:
                if selected.contains(cursor) { selected.remove(cursor) }
                else { selected.insert(cursor) }
                draw()
            case .enter:
                return selected
            default: break
            }
        }
    }
}
