#if canImport(Testing)
import Testing
import Foundation
@testable import SwiftTemplateCLI

// MARK: - GreetCommand Tests

@Suite("GreetCommand")
struct GreetCommandTests {
    @Test func parseDefaults() throws {
        let cmd = try GreetCommand.parse(["Alice"])
        #expect(cmd.name == "Alice")
        #expect(cmd.greeting == "Hello")
        #expect(cmd.count == 1)
        #expect(cmd.shout == false)
        #expect(cmd.emoji == true)
    }

    @Test func parseAllOptions() throws {
        let cmd = try GreetCommand.parse(["Bob", "--greeting", "Hi", "--count", "3", "--shout", "--no-emoji"])
        #expect(cmd.name == "Bob")
        #expect(cmd.greeting == "Hi")
        #expect(cmd.count == 3)
        #expect(cmd.shout == true)
        #expect(cmd.emoji == false)
    }

    @Test func validationRejectsInvalidCount() {
        #expect(throws: (any Error).self) { try GreetCommand.parse(["Alice", "--count", "0"]) }
        #expect(throws: (any Error).self) { try GreetCommand.parse(["Alice", "--count", "101"]) }
    }
}

// MARK: - GenerateCommand Tests

@Suite("GenerateCommand")
struct GenerateCommandTests {
    @Test func uuidDefaults() throws {
        let cmd = try GenerateCommand.UUID.parse([])
        #expect(cmd.count == 1)
        #expect(cmd.uppercase == false)
    }

    @Test func uuidRejectsZero() {
        #expect(throws: (any Error).self) { try GenerateCommand.UUID.parse(["--count", "0"]) }
    }

    @Test func passwordDefaults() throws {
        let cmd = try GenerateCommand.Password.parse([])
        #expect(cmd.length == 16)
        #expect(cmd.charset == .alphanumeric)
    }

    @Test func passwordCharsetParsing() throws {
        let cmd = try GenerateCommand.Password.parse(["--charset", "ascii", "--length", "32"])
        #expect(cmd.charset == .ascii)
        #expect(cmd.length == 32)
    }

    @Test func passwordValidation() {
        #expect(throws: (any Error).self) { try GenerateCommand.Password.parse(["--length", "7"]) }
        #expect(throws: (any Error).self) { try GenerateCommand.Password.parse(["--length", "257"]) }
    }
}

// MARK: - ConfigCommand Tests

@Suite("ConfigCommand")
struct ConfigCommandTests {
    @Test func parseDefaults() throws {
        let cmd = try ConfigCommand.parse([])
        #expect(cmd.config == nil)
        #expect(cmd.name == nil)
        #expect(cmd.logLevel == nil)
        #expect(cmd.verbose == false)
    }

    @Test func parseAllFlags() throws {
        let cmd = try ConfigCommand.parse(["--name", "MyApp", "--log-level", "debug", "--verbose"])
        #expect(cmd.name == "MyApp")
        #expect(cmd.logLevel == "debug")
        #expect(cmd.verbose == true)
    }

    @Test func configDecoding() throws {
        let json = #"{"name":"TestApp","verbose":true,"logLevel":"warn"}"#
        let data = Data(json.utf8)
        let config = try JSONDecoder().decode(ConfigCommand.AppConfig.self, from: data)
        #expect(config.name == "TestApp")
        #expect(config.verbose == true)
        #expect(config.logLevel == "warn")
    }
}

// MARK: - FormatCommand Tests

@Suite("TableFormatter")
struct TableFormatterTests {
    @Test func renderAlignment() {
        var table = TableFormatter(headers: ["Name", "Value"])
        table.rows = [["short", "1"], ["longer name", "2"]]
        let output = table.render(color: false)
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.count == 4)
        #expect(lines[0].contains("Name"))
        #expect(lines[0].contains("Value"))
        #expect(lines[1].contains("─"))
    }
}

@Suite("ProgressValidation")
struct ProgressValidationTests {
    @Test func rejectsInvalidSteps() {
        #expect(throws: (any Error).self) { try FormatCommand.ProgressSubcommand.parse(["--steps", "0"]) }
        #expect(throws: (any Error).self) { try FormatCommand.ProgressSubcommand.parse(["--steps", "101"]) }
    }

    @Test func acceptsValidSteps() throws {
        let cmd = try FormatCommand.ProgressSubcommand.parse(["--steps", "50"])
        #expect(cmd.steps == 50)
    }
}

// MARK: - ANSIStyle Tests

@Suite("ANSIStyle")
struct ANSIStyleTests {
    @Test func applyWrapsWithReset() {
        let styled = ANSIStyle.red.apply("error")
        #expect(styled.hasPrefix("\u{001B}[31m"))
        #expect(styled.hasSuffix("\u{001B}[0m"))
        #expect(styled.contains("error"))
    }
}

// MARK: - PipeCommand Tests

@Suite("PipeCommand")
struct PipeCommandTests {
    @Test func parseDefaults() throws {
        let cmd = try PipeCommand.parse([])
        #expect(cmd.transform == .uppercase)
        #expect(cmd.filter == nil)
    }

    @Test func parseTransformAndFilter() throws {
        let cmd = try PipeCommand.parse(["--transform", "lowercase", "--filter", "hello"])
        #expect(cmd.transform == .lowercase)
        #expect(cmd.filter == "hello")
    }
}

// MARK: - Root Command Tests

@Suite("RootCommand")
struct RootCommandTests {
    @Test func subcommandsRegistered() {
        let names = SwiftTemplateCLI.configuration.subcommands.map {
            $0.configuration.commandName ?? ""
        }
        #expect(names.contains("greet"))
        #expect(names.contains("generate"))
        #expect(names.contains("config"))
        #expect(names.contains("pipe"))
        #expect(names.contains("format"))
        #expect(names.contains("platform"))
    }
}

// MARK: - Run Method Tests

@Suite("GreetCommandRun")
struct GreetCommandRunTests {
    @Test func runDefault() throws {
        var cmd = try GreetCommand.parse(["World"])
        try cmd.run()
    }

    @Test func runShoutNoEmoji() throws {
        var cmd = try GreetCommand.parse(["Alice", "--shout", "--no-emoji", "--count", "2"])
        try cmd.run()
    }
}

@Suite("GenerateCommandRun")
struct GenerateCommandRunTests {
    @Test func uuidRun() throws {
        var cmd = try GenerateCommand.UUID.parse(["--count", "2"])
        try cmd.run()
    }

    @Test func uuidUppercase() throws {
        var cmd = try GenerateCommand.UUID.parse(["--uppercase"])
        try cmd.run()
    }

    @Test func passwordAlphanumeric() throws {
        var cmd = try GenerateCommand.Password.parse([])
        try cmd.run()
    }

    @Test func passwordNumeric() throws {
        var cmd = try GenerateCommand.Password.parse(["--charset", "numeric"])
        try cmd.run()
    }

    @Test func passwordAscii() throws {
        var cmd = try GenerateCommand.Password.parse(["--charset", "ascii", "--length", "32"])
        try cmd.run()
    }
}

@Suite("ConfigCommandRun")
struct ConfigCommandRunTests {
    @Test func runDefaults() throws {
        var cmd = try ConfigCommand.parse([])
        try cmd.run()
    }

    @Test func runWithFlags() throws {
        var cmd = try ConfigCommand.parse(["--name", "TestApp", "--log-level", "debug", "--verbose"])
        try cmd.run()
    }

    @Test func runWithConfigFile() throws {
        let tmp = NSTemporaryDirectory() + "swift-test-config-\(UUID().uuidString).json"
        let json = #"{"name":"FileApp","verbose":false,"logLevel":"warn"}"#
        try json.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        var cmd = try ConfigCommand.parse(["--config", tmp, "--verbose"])
        try cmd.run()
    }
}

@Suite("FormatCommandRun")
struct FormatCommandRunTests {
    @Test func tableRun() throws {
        var cmd = try FormatCommand.TableSubcommand.parse(["--no-color"])
        cmd.run()
    }

    @Test func colorsRun() throws {
        var cmd = try FormatCommand.ColorsSubcommand.parse([])
        cmd.run()
    }

    @Test func tableRenderWithColor() {
        var table = TableFormatter(headers: ["A", "B"])
        table.rows = [["x", "y"]]
        let output = table.render(color: true)
        #expect(output.contains("A"))
    }

    @Test func supportsColorCheck() {
        // In test environment, stdout is not a tty
        _ = supportsColor()
    }
}

@Suite("PlatformCommandRun")
struct PlatformCommandRunTests {
    @Test func infoRun() throws {
        var cmd = try PlatformCommand.InfoSubcommand.parse([])
        cmd.run()
    }

    @Test func pathsRun() throws {
        var cmd = try PlatformCommand.PathsSubcommand.parse([])
        cmd.run()
    }

    @Test func platformProperties() {
        #expect(!Platform.name.isEmpty)
        #expect(!Platform.arch.isEmpty)
        #expect(!Platform.homeDirectory.isEmpty)
        #expect(!Platform.configDirectory.isEmpty)
        #expect(!Platform.cacheDirectory.isEmpty)
        #expect(!Platform.hostname.isEmpty)
    }
}

@Suite("FetchCommandValidation")
struct FetchCommandValidationTests {
    @Test func validURL() throws {
        var cmd = try FetchCommand.parse(["https://example.com"])
        try cmd.validate()
    }

    @Test func timeoutOption() throws {
        let cmd = try FetchCommand.parse(["https://example.com", "--timeout", "10"])
        #expect(cmd.timeout == 10.0)
    }

    @Test func invalidTimeout() {
        #expect(throws: (any Error).self) {
            var cmd = try FetchCommand.parse(["https://example.com", "--timeout", "-1"])
            try cmd.validate()
        }
    }
}

@Suite("PipeCommandExtended")
struct PipeCommandExtendedTests {
    @Test func lineNumbersTransform() throws {
        let cmd = try PipeCommand.parse(["--transform", "line-numbers"])
        #expect(cmd.transform == .lineNumbers)
    }
}

#endif
