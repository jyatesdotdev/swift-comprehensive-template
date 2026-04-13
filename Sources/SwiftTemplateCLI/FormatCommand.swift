import ArgumentParser
import Foundation

// MARK: - ANSI Styling

/// Minimal ANSI terminal styling — works on macOS and Linux.
enum ANSIStyle: String {
    case reset = "\u{001B}[0m"
    case bold = "\u{001B}[1m"
    case dim = "\u{001B}[2m"
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"
    case blue = "\u{001B}[34m"
    case cyan = "\u{001B}[36m"

    func apply(_ text: String) -> String { "\(rawValue)\(text)\(ANSIStyle.reset.rawValue)" }
}

/// Returns true if stdout supports ANSI colors.
func supportsColor() -> Bool {
    #if os(Windows)
    return false
    #else
    return isatty(STDOUT_FILENO) != 0 && ProcessInfo.processInfo.environment["NO_COLOR"] == nil
    #endif
}

// MARK: - Table Formatter

/// Formats rows into aligned columns with optional headers.
struct TableFormatter {
    let headers: [String]
    var rows: [[String]] = []

    func render(color: Bool = false) -> String {
        let allRows = [headers] + rows
        let colCount = headers.count
        // Calculate max width per column
        let widths = (0..<colCount).map { col in
            allRows.map { $0.indices.contains(col) ? $0[col].count : 0 }.max() ?? 0
        }

        var lines: [String] = []
        // Header
        let header = headers.enumerated().map { i, h in
            h.padding(toLength: widths[i], withPad: " ", startingAt: 0)
        }.joined(separator: "  ")
        lines.append(color ? ANSIStyle.bold.apply(header) : header)
        // Separator
        lines.append(widths.map { String(repeating: "─", count: $0) }.joined(separator: "──"))
        // Data rows
        for row in rows {
            let line = row.enumerated().map { i, cell in
                cell.padding(toLength: widths[i], withPad: " ", startingAt: 0)
            }.joined(separator: "  ")
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Format Command

struct FormatCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "format",
        abstract: "Output formatting examples — tables, colors, progress indicators.",
        subcommands: [TableSubcommand.self, ColorsSubcommand.self, ProgressSubcommand.self]
    )
}

// MARK: - Table Subcommand

extension FormatCommand {
    struct TableSubcommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "table",
            abstract: "Render sample data as an aligned table."
        )

        @Flag(name: .long, help: "Disable colored output.")
        var noColor = false

        func run() {
            let useColor = !noColor && supportsColor()
            var table = TableFormatter(headers: ["Name", "Language", "Stars"])
            table.rows = [
                ["swift-argument-parser", "Swift", "3.4k"],
                ["Vapor", "Swift", "24.5k"],
                ["swift-nio", "Swift", "7.9k"]
            ]
            print(table.render(color: useColor))
        }
    }
}

// MARK: - Colors Subcommand

extension FormatCommand {
    struct ColorsSubcommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "colors",
            abstract: "Demonstrate ANSI color and style output."
        )

        func run() {
            guard supportsColor() else {
                print("Terminal does not support colors (set NO_COLOR to disable, or pipe detected).")
                return
            }
            let styles: [(String, ANSIStyle)] = [
                ("Bold", .bold), ("Dim", .dim), ("Red", .red),
                ("Green", .green), ("Yellow", .yellow), ("Blue", .blue), ("Cyan", .cyan)
            ]
            for (label, style) in styles {
                print(style.apply(label))
            }
            // Practical example: status messages
            print()
            print("\(ANSIStyle.green.rawValue)✓\(ANSIStyle.reset.rawValue) Build succeeded")
            print("\(ANSIStyle.yellow.rawValue)⚠\(ANSIStyle.reset.rawValue) 2 warnings")
            print("\(ANSIStyle.red.rawValue)✗\(ANSIStyle.reset.rawValue) 1 error")
        }
    }
}

// MARK: - Progress Subcommand

extension FormatCommand {
    struct ProgressSubcommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "progress",
            abstract: "Demonstrate a terminal progress bar."
        )

        @Option(help: "Number of steps (1–100).")
        var steps: Int = 20

        func validate() throws {
            guard (1...100).contains(steps) else {
                throw ValidationError("Steps must be 1–100.")
            }
        }

        func run() async throws {
            let barWidth = 30
            for i in 1...steps {
                let fraction = Double(i) / Double(steps)
                let filled = Int(fraction * Double(barWidth))
                let empty = barWidth - filled
                let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
                let pct = String(format: "%3.0f%%", fraction * 100)
                // \r overwrites the current line — standard progress pattern
                print("\r[\(bar)] \(pct) (\(i)/\(steps))", terminator: "")
                fflush(stdout)
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            }
            print() // final newline
        }
    }
}
