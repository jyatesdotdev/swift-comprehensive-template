import ArgumentParser
import Foundation

/// Demonstrates stdin/stdout piping — reads from standard input, transforms, writes to stdout.
struct PipeCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pipe",
        abstract: "Transform text from stdin and write to stdout.",
        discussion: """
        Usage examples:
          echo "hello world" | swift-template pipe --uppercase
          cat file.txt | swift-template pipe --line-numbers
          swift-template pipe --lowercase < input.txt > output.txt
        """
    )

    enum Transform: String, ExpressibleByArgument, CaseIterable {
        case uppercase, lowercase, lineNumbers = "line-numbers"
    }

    @Option(name: .long, help: "Transform to apply: \(Transform.allCases.map(\.rawValue).joined(separator: ", ")).")
    var transform: Transform = .uppercase

    @Option(name: .long, help: "Only output lines matching this substring.")
    var filter: String?

    func run() throws {
        var lineNumber = 0
        while let line = readLine(strippingNewline: false) {
            lineNumber += 1

            // Apply filter if specified
            if let filter, !line.localizedCaseInsensitiveContains(filter) {
                continue
            }

            let trimmed = line.hasSuffix("\n") ? String(line.dropLast()) : line
            switch transform {
            case .uppercase:
                print(trimmed.uppercased())
            case .lowercase:
                print(trimmed.lowercased())
            case .lineNumbers:
                print("\(lineNumber)\t\(trimmed)")
            }
        }
    }
}
