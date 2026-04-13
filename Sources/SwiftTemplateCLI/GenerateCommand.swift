import ArgumentParser
import Foundation

/// Demonstrates enum arguments, @Option transforms, and subcommands within a subcommand.
struct GenerateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate random values.",
        subcommands: [UUID.self, Password.self]
    )
}

// MARK: - Nested Subcommands

extension GenerateCommand {
    /// `generate uuid` — demonstrates @Option with default, @Flag.
    struct UUID: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Generate random UUIDs."
        )

        @Option(name: .shortAndLong, help: "How many UUIDs to generate.")
        var count: Int = 1

        @Flag(name: .long, help: "Output uppercase UUIDs.")
        var uppercase = false

        func validate() throws {
            guard count > 0 else {
                throw ValidationError("--count must be at least 1.")
            }
        }

        func run() throws {
            for _ in 0..<count {
                let id = Foundation.UUID().uuidString
                print(uppercase ? id.uppercased() : id.lowercased())
            }
        }
    }

    /// `generate password` — demonstrates @Option with custom parsing and enum @Option.
    struct Password: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Generate a random password."
        )

        enum Charset: String, ExpressibleByArgument, CaseIterable { // swiftlint:disable:this nesting
            case alphanumeric, ascii, numeric
        }

        @Option(name: .shortAndLong, help: "Password length (8–256).")
        var length: Int = 16

        @Option(name: .shortAndLong,
                help: "Character set: \(Charset.allCases.map(\.rawValue).joined(separator: ", ")).")
        var charset: Charset = .alphanumeric

        func validate() throws {
            guard (8...256).contains(length) else {
                throw ValidationError("--length must be between 8 and 256.")
            }
        }

        func run() throws {
            let chars: [Character] = {
                switch charset {
                case .numeric:
                    return Array("0123456789")
                case .alphanumeric:
                    return Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
                case .ascii:
                    return Array(
                        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?"
                    )
                }
            }()
            guard let sample = chars.randomElement() else { return }
            let password = String((0..<length).map { _ in chars.randomElement() ?? sample })
            print(password)
        }
    }
}
