# CLI Development Guide

## Overview

SwiftTemplateCLI demonstrates building command-line tools in Swift using [swift-argument-parser](https://github.com/apple/swift-argument-parser). It covers argument parsing, subcommands, config management, piping, output formatting, cross-platform patterns, and testing.

## Quick Start

```bash
swift build
.build/debug/SwiftTemplateCLI --help
.build/debug/SwiftTemplateCLI greet World
.build/debug/SwiftTemplateCLI generate uuid --count 5
```

## Package Setup

Add swift-argument-parser as a dependency in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
],
targets: [
    .executableTarget(
        name: "SwiftTemplateCLI",
        dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]
    ),
]
```

## Root Command

Use `@main` and `AsyncParsableCommand` as the entry point. Register subcommands via `CommandConfiguration`:

```swift
@main
struct SwiftTemplateCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swift-template",
        abstract: "SwiftTemplate CLI — demonstrates argument-parser patterns.",
        version: "1.0.0",
        subcommands: [GreetCommand.self, GenerateCommand.self, FetchCommand.self]
    )
}
```

Use `AsyncParsableCommand` at the root if any subcommand is async.

## Argument Parsing

### @Argument — Positional Arguments

```swift
@Argument(help: "The name to greet.")
var name: String
```

### @Option — Named Options

```swift
@Option(name: .shortAndLong, help: "The greeting to use.")
var greeting: String = "Hello"
```

### @Flag — Boolean Flags

```swift
@Flag(name: .shortAndLong, help: "SHOUT the greeting.")
var shout = false

// Invertible flag: --emoji / --no-emoji
@Flag(inversion: .prefixedNo, help: "Include emoji in output.")
var emoji = true
```

### Enum Arguments

Conform to `ExpressibleByArgument` and `CaseIterable`:

```swift
enum Charset: String, ExpressibleByArgument, CaseIterable {
    case alphanumeric, ascii, numeric
}

@Option(help: "Character set: \(Charset.allCases.map(\.rawValue).joined(separator: ", ")).")
var charset: Charset = .alphanumeric
```

### Validation

Override `validate()` to enforce constraints before `run()`:

```swift
func validate() throws {
    guard (1...100).contains(count) else {
        throw ValidationError("--count must be between 1 and 100.")
    }
}
```

## Subcommands

### Flat Subcommands

Register subcommands in the parent's `CommandConfiguration.subcommands` array.

### Nested Subcommands

A subcommand can itself have subcommands (e.g., `generate uuid`, `generate password`):

```swift
struct GenerateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate random values.",
        subcommands: [UUID.self, Password.self]
    )
}

extension GenerateCommand {
    struct UUID: ParsableCommand {
        // ...
    }
}
```

## Async Commands

Use `AsyncParsableCommand` and `async throws` on `run()`:

```swift
struct FetchCommand: AsyncParsableCommand {
    func run() async throws {
        let (data, response) = try await URLSession.shared.data(for: request)
    }
}
```

## Real-World Patterns

### Config File Parsing

Load a JSON config with `Codable`, then layer resolution: CLI flags → env vars → file → defaults.

```swift
let resolvedName = name                              // CLI flag (highest priority)
    ?? env["SWIFT_TEMPLATE_NAME"]                    // Environment variable
    ?? fileConfig?.name                              // Config file
    ?? "SwiftTemplate"                               // Default
```

See `ConfigCommand.swift` for the full implementation.

### Environment Variables

Read via `ProcessInfo.processInfo.environment`:

```swift
let env = ProcessInfo.processInfo.environment
let logLevel = env["SWIFT_TEMPLATE_LOG_LEVEL"] ?? "info"
```

### Stdin/Stdout Piping

Read stdin line-by-line with `readLine()`, write to stdout with `print()`:

```swift
while let line = readLine(strippingNewline: false) {
    print(line.uppercased())
}
```

Usage:

```bash
echo "hello" | swift-template pipe --transform uppercase
cat file.txt | swift-template pipe --filter "error" --transform line-numbers
swift-template pipe < input.txt > output.txt
```

## Output Formatting

### Aligned Tables

`TableFormatter` calculates column widths and pads cells:

```swift
var table = TableFormatter(headers: ["Name", "Language", "Stars"])
table.rows = [["Vapor", "Swift", "24.5k"]]
print(table.render(color: supportsColor()))
```

### ANSI Colors

Use escape codes, but respect `NO_COLOR` and TTY detection:

```swift
enum ANSIStyle: String {
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case reset = "\u{001B}[0m"

    func apply(_ text: String) -> String { "\(rawValue)\(text)\(ANSIStyle.reset.rawValue)" }
}

func supportsColor() -> Bool {
    isatty(STDOUT_FILENO) != 0 && ProcessInfo.processInfo.environment["NO_COLOR"] == nil
}
```

Best practices:
- Always check `isatty()` — don't emit escape codes when piped
- Honor the `NO_COLOR` convention (https://no-color.org)
- Provide a `--no-color` flag as an override

### Progress Indicators

Overwrite the current line with `\r` for animated progress:

```swift
print("\r[\(bar)] \(pct)", terminator: "")
fflush(stdout)
```

## Cross-Platform Compatibility

### Conditional Compilation

```swift
#if os(macOS)
// macOS-specific code
#elseif os(Linux)
// Linux-specific code
#endif

#if arch(arm64)
// ARM64-specific code
#endif
```

### Platform-Appropriate Directories

Follow OS conventions — `~/Library/` on macOS, XDG on Linux:

```swift
static var configDirectory: String {
    #if os(macOS)
    return homeDirectory + "/Library/Application Support"
    #elseif os(Linux)
    return ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"]
        ?? (homeDirectory + "/.config")
    #endif
}
```

### Linux Networking Import

`URLSession` requires an extra import on Linux:

```swift
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
```

### Signal Handling

POSIX `signal()` works on both macOS and Linux:

```swift
signal(SIGINT) { _ in
    print("\nCaught SIGINT — cleaning up...")
    _Exit(0)
}
```

## Testing CLI Commands

Test commands by constructing them with arguments and calling `run()`:

```swift
import Testing
@testable import SwiftTemplateCLI

@Suite("GreetCommand")
struct GreetCommandTests {
    @Test func defaultGreeting() throws {
        var cmd = try GreetCommand.parse(["World"])
        // Validate parsed values
        #expect(cmd.name == "World")
        #expect(cmd.greeting == "Hello")
        #expect(cmd.shout == false)
    }

    @Test func validationRejectsInvalidCount() {
        #expect(throws: (any Error).self) {
            _ = try GreetCommand.parse(["World", "--count", "0"])
        }
    }
}
```

Key patterns:
- Use `Command.parse([...])` to construct commands from argument arrays
- Test validation by checking that invalid args throw
- Test parsed values directly on the struct properties
- For output testing, redirect stdout or extract logic into testable functions

## File Structure

```
Sources/SwiftTemplateCLI/
├── SwiftTemplateCLI.swift    # Root @main command
├── GreetCommand.swift        # @Argument, @Option, @Flag, validation
├── GenerateCommand.swift     # Nested subcommands, enum args
├── FetchCommand.swift        # AsyncParsableCommand, Linux compat
├── ConfigCommand.swift       # JSON config, env vars, priority resolution
├── PipeCommand.swift         # stdin/stdout piping, transforms
├── FormatCommand.swift       # Tables, ANSI colors, progress bars
└── PlatformCommand.swift     # Cross-platform detection, XDG, signals
```

## Best Practices

1. **One command per file** — keeps the codebase navigable
2. **Always add `help:` strings** — they become the `--help` output
3. **Use `validate()`** — catch bad input before `run()` executes
4. **Respect `NO_COLOR` and TTY** — don't break piped output with escape codes
5. **Layer config resolution** — CLI flags > env vars > config file > defaults
6. **Use `#if canImport`** — for conditional platform imports (e.g., FoundationNetworking)
7. **Test with `Command.parse()`** — construct commands from string arrays for unit tests
8. **Use `discussion:` in CommandConfiguration** — for extended help text with usage examples

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [EXTENDING.md](EXTENDING.md) · [TUTORIAL.md](TUTORIAL.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
