import ArgumentParser
import Foundation

/// Demonstrates config file parsing (JSON + Codable) and environment variable fallbacks.
struct ConfigCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Show resolved configuration from file, env vars, and flags.",
        discussion: """
        Resolution order (highest priority first):
          1. Command-line flags
          2. Environment variables (SWIFT_TEMPLATE_*)
          3. Config file values
          4. Built-in defaults
        """
    )

    // MARK: - Config File Model

    struct AppConfig: Codable {
        var name: String?
        var verbose: Bool? // swiftlint:disable:this discouraged_optional_boolean
        var logLevel: String?
    }

    // MARK: - Arguments

    @Option(name: .long, help: "Path to JSON config file.")
    var config: String?

    @Option(name: .shortAndLong, help: "Application name. Env: SWIFT_TEMPLATE_NAME")
    var name: String?

    @Option(name: .shortAndLong, help: "Log level (debug, info, warn, error). Env: SWIFT_TEMPLATE_LOG_LEVEL")
    var logLevel: String?

    @Flag(name: .shortAndLong, help: "Enable verbose output. Env: SWIFT_TEMPLATE_VERBOSE=1")
    var verbose = false

    // MARK: - Execution

    func run() throws {
        let fileConfig = try loadConfigFile()
        let env = ProcessInfo.processInfo.environment

        // Resolve with priority: flag > env > file > default
        let resolvedName = name
            ?? env["SWIFT_TEMPLATE_NAME"]
            ?? fileConfig?.name
            ?? "SwiftTemplate"

        let resolvedLogLevel = logLevel
            ?? env["SWIFT_TEMPLATE_LOG_LEVEL"]
            ?? fileConfig?.logLevel
            ?? "info"

        let resolvedVerbose = verbose
            || env["SWIFT_TEMPLATE_VERBOSE"] == "1"
            || (fileConfig?.verbose ?? false)

        print("Resolved configuration:")
        print("  name:      \(resolvedName)")
        print("  logLevel:  \(resolvedLogLevel)")
        print("  verbose:   \(resolvedVerbose)")

        if resolvedVerbose, let path = config {
            print("  source:    \(path)")
        }
    }

    private func loadConfigFile() throws -> AppConfig? {
        guard let path = config else { return nil }
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AppConfig.self, from: data)
    }
}
