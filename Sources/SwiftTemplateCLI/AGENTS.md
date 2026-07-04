# AGENTS.md — SwiftTemplateCLI Target

An ArgumentParser-based CLI (`swift-template`) demonstrating real-world command
patterns. **One subcommand per file**, registered on the root command in
`SwiftTemplateCLI.swift`.

## Layout

- `SwiftTemplateCLI.swift` — `@main` root `AsyncParsableCommand`; only holds
  `CommandConfiguration` (name, abstract, `version: SwiftTemplate.version`,
  subcommand list). No logic here.
- `GreetCommand.swift` — canonical example: `@Argument`, `@Option(name:
  .shortAndLong)`, `@Flag`, flag inversion (`--emoji/--no-emoji`), `validate()`.
- `GenerateCommand.swift` — nested subcommands declared in an `extension` of the
  parent; enum options via `ExpressibleByArgument, CaseIterable`.
- `FetchCommand.swift` — `AsyncParsableCommand` with `func run() async throws`.
- `ConfigCommand.swift` — layered config resolution: flag > env
  (`SWIFT_TEMPLATE_*`) > JSON file (`Codable`) > default.
- `PipeCommand.swift` — stdin/stdout streaming via `readLine`.
- `FormatCommand.swift` — ANSI styling (`ANSIStyle`, `supportsColor()`),
  `TableFormatter`, progress bar.
- `PlatformCommand.swift` — cross-platform info. ⚠️ Defines a **file-local
  `Platform` enum** distinct from `SwiftTemplate.Platform` in
  `CrossPlatform.swift`. If both are in scope, qualify explicitly.

## Checklist: adding a subcommand

1. Create `NewCommand.swift` containing one `struct NewCommand: ParsableCommand`
   (or `AsyncParsableCommand` only if `run` genuinely awaits).
2. Give it a `CommandConfiguration` with `commandName` (kebab-case) and
   `abstract`. Multi-line usage examples go in `discussion`.
3. Every `@Option`/`@Flag` gets `help:`. Enum-valued options conform to
   `ExpressibleByArgument, CaseIterable` and list values in the help string:
   `help: "Charset: \(Charset.allCases.map(\.rawValue).joined(separator: ", "))."`.
4. Input constraints go in `func validate() throws` throwing
   `ValidationError("--count must be between 1 and 100.")` — never trap or
   `fatalError` on bad input.
5. Register the type in the root command's `subcommands:` array.
6. Add tests in `Tests/SwiftTemplateCLITests/SwiftTemplateCLITests.swift`:
   a parse-defaults test, a parse-all-options test, a validation-rejection test
   (`#expect(throws: (any Error).self) { try NewCommand.parse([...]) }`), and a
   `run()` smoke test. Also extend the `RootCommand` `subcommandsRegistered` test.

## Conventions & constraints

- Types here are **internal** (no `public`) — this is an executable target, and
  tests use `@testable import SwiftTemplateCLI`.
- Reusable logic belongs in the `SwiftTemplate` library; this target should
  only contain argument parsing, I/O, and presentation.
- Keep commands **testable without side effects**: parsing and validation are
  tested via `Type.parse([...])`; keep `run()` thin.
- Linux: `URLSession` requires the `#if canImport(FoundationNetworking)` import
  (see `FetchCommand.swift`); libc imports use the Darwin/Glibc/Musl switch
  (see `PlatformCommand.swift`).
- Respect `NO_COLOR` and non-TTY output — route all ANSI output through
  `supportsColor()` / `ANSIStyle`, never print raw escape codes unconditionally.
- Exit with `ValidationError`/thrown errors and let ArgumentParser format them;
  don't call `exit()` directly (the signal demo's `_Exit` in a C handler is the
  one deliberate exception).
