# AGENTS.md — SwiftTemplate Agent Guide

This is the master guide for AI agents working in this repository. Every major
directory has its own `AGENTS.md` with rules specific to that directory — **always
read the nearest `AGENTS.md` to the files you are editing before making changes.**

## What This Repository Is

A cross-platform Swift Package Manager **template and teaching codebase**. The code
itself is the documentation: every file demonstrates idiomatic, modern Swift
(protocol-oriented design, strict concurrency, SIMD, Metal, ArgumentParser CLIs).
Because readers copy patterns from this repo, **code quality is the product**.
A working-but-sloppy change is a failed change here.

Toolchain: Swift tools version 5.9 manifest, but tests use Swift Testing, which
needs a Swift 6 / Xcode 16.2+ toolchain (CI uses macos-15 and the newest
available Xcode 16.x).

## Directory Map

| Directory | Contents | Guide |
|---|---|---|
| `Sources/SwiftTemplate/` | Core library — all domain modules | `Sources/SwiftTemplate/AGENTS.md` |
| `Sources/SwiftTemplate/Concurrency/` | GCD, async/await, actors, TaskGroups | own `AGENTS.md` |
| `Sources/SwiftTemplate/HPC/` | SIMD, Accelerate, parallel compute | own `AGENTS.md` |
| `Sources/SwiftTemplate/Rendering/` | Metal, Core Graphics, SwiftUI, software rendering | own `AGENTS.md` |
| `Sources/SwiftTemplate/Simulation/` | Numerical integration, physics | own `AGENTS.md` |
| `Sources/SwiftTemplate/Systems/` | File I/O, processes, signals, unsafe memory | own `AGENTS.md` |
| `Sources/SwiftTemplateUI/` | SwiftUI building blocks (macOS-first, Apple-only) | `Sources/SwiftTemplateUI/AGENTS.md` |
| `Sources/SwiftTemplateCLI/` | ArgumentParser CLI, one subcommand per file | `Sources/SwiftTemplateCLI/AGENTS.md` |
| `Sources/SwiftTemplateUIDemo/` | macOS demo app for the UI target | own `AGENTS.md` |
| `Sources/SwiftTemplateExample/` | Minimal executable smoke-test of the library | own `AGENTS.md` |
| `Tests/` | Swift Testing suites mirroring the sources | `Tests/AGENTS.md` |
| `docs/` | Human-facing guides, one per module | `docs/AGENTS.md` |
| `scripts/` | `security-scan.sh` (SwiftLint, audit, Periphery, Trivy) | `scripts/AGENTS.md` |

## Commands

```bash
swift build                                  # Build everything
swift test                                   # Run all tests
swift test --filter HPCTests                 # One suite
swift test --filter HPCTests/simdDot         # One test
swift run SwiftTemplateCLI greet Alice       # Run the CLI
swift run SwiftTemplateUIDemo                # Launch the macOS UI demo app
swiftlint lint --strict                      # Lint — CI fails on ANY violation
make verify                                  # build + test + strict lint in one shot
make coverage                                # Tests + the 80% coverage gate CI enforces
make security                                # Full security scan
```

Before finishing any change, run `make verify` (and `make coverage` if you
added or removed code).

## Hard Rules (CI gates — violations fail the build)

1. **Never use `!` force-unwrap, `as!`, or `try!`** — anywhere, including tests.
   SwiftLint promotes `force_unwrapping`, `force_cast`, and `force_try` to
   **errors**. Use `guard let`, `if let`, `??`, `as?`, or throw instead.
2. **Swift Testing only** (`import Testing`, `@Suite`, `@Test`, `#expect`).
   Never `import XCTest`. XCTest was deliberately removed from this repo.
3. **80% minimum code coverage**, enforced locally by `make coverage` /
   `scripts/check-coverage.sh` over the core library and CLI (the UI target and
   entry-point executables are excluded — see the script header). CI runs
   `swift test` without coverage because instrumentation hangs on GitHub-hosted macOS.
   New public API needs tests.
4. **Code must compile on Linux.** Guard Apple-only frameworks with
   `#if canImport(Metal)` / `#if canImport(Accelerate)` / `#if os(macOS)`.
   On Linux, `URLSession` needs `#if canImport(FoundationNetworking)`.
   The UI targets are Apple-only by design but stay Linux-buildable via
   whole-file `#if canImport(SwiftUI)` guards and a fallback `@main`.
5. **StrictConcurrency is enabled** on the library target. All library types must
   be `Sendable`-clean. Escapes (`@unchecked Sendable`, `nonisolated(unsafe)`)
   require a justification comment on the same line or directly above.
6. **SwiftLint size limits**: lines ≤120 (hard 200), function bodies ≤50 (hard
   100), type bodies ≤300 (hard 500), files ≤500 (hard 1000), cyclomatic
   complexity ≤10 (hard 20). Split code rather than approach the hard limits.

## House Style (copy these patterns, they are used everywhere)

- **Namespaces are caseless `public enum`s** (`public enum SIMDOps { ... }`),
  never empty structs or free functions.
- **Every public symbol has a `///` DocC comment** with `- Parameters:`,
  `- Returns:`, and `- Throws:` sections where applicable. Cross-reference other
  symbols with ``` ``DoubleBackticks`` ```.
- **Errors are typed nested enums** conforming to `Error` with associated values
  (`FileSystem.FSError.notFound(path)`), not `NSError` or string throws.
- **Files are organized with numbered `// MARK: - N. Section` headers.**
- **Inline SwiftLint disables** are a last resort and use the trailing form with
  the specific rule: `// swiftlint:disable:this shorthand_operator`.
- Value types (`struct`) by default; `final class` only for reference semantics
  (COW storage, resource ownership); `actor` for shared mutable state.

## Definition of Done — check before finishing any change

1. `swift build` succeeds with no warnings introduced.
2. `swift test` passes; new code has tests in the mirrored `Tests/` file.
3. `swiftlint lint --strict` reports zero violations.
4. Public API has complete DocC comments.
5. Cross-platform: no unguarded Apple-framework imports.
6. If you added or changed a module: the matching guide in `docs/` and
   `docs/ARCHITECTURE.md` are updated (see `docs/AGENTS.md`).

## Task Routing

| Task | Where to start |
|---|---|
| Add a Swift pattern/utility to an existing domain | The domain dir under `Sources/SwiftTemplate/` — read its `AGENTS.md` |
| Add a whole new domain module | `docs/EXTENDING.md`, then `Sources/SwiftTemplate/AGENTS.md` |
| Add a CLI subcommand | `Sources/SwiftTemplateCLI/AGENTS.md` (has a checklist) |
| Add UI components, view models, or app screens | `Sources/SwiftTemplateUI/AGENTS.md`, `docs/UIGuide.md` |
| Add or fix tests | `Tests/AGENTS.md` |
| Change lint/security tooling | `scripts/AGENTS.md`, `.swiftlint.yml`, `.github/workflows/` |
| Understand target/dependency layout | `Package.swift`, `docs/ARCHITECTURE.md` |
