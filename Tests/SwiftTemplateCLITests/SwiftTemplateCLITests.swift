#if canImport(Testing)
import Testing
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

#endif
