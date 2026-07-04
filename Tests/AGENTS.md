# AGENTS.md — Tests

Three test targets, all using **Swift Testing exclusively**:

- `SwiftTemplateTests/` — library tests, **one file per source file/module**
  (`HPC.swift` → `HPCTests.swift`). Keep that mirror when adding sources.
- `SwiftTemplateCLITests/` — CLI tests, single file, one `@Suite` per command
  concern.
- `SwiftTemplateUITests/` — UI-target tests: view models (`@MainActor`
  suites), `LoadState`, the pixel-buffer image bridge, and scene logic. View
  bodies are not unit-tested and are excluded from the coverage gate.

## Hard rules

1. `import Testing` — **never** `import XCTest`. XCTest was deliberately
   removed (see git history); do not reintroduce it, including "fallback" paths.
2. No `!` force-unwrap, `as!`, or `try!` — SwiftLint errors apply to tests too.
   Use `try` inside `throws` test functions and `#expect(throws:)` for failures.
3. CI enforces **80% coverage** via `scripts/check-coverage.sh` (core library
   and CLI; UI views and entry-point executables excluded) — a new public API
   needs tests in the mirrored file before CI will pass. Check locally with
   `make coverage`.
4. No trailing blank lines / style violations — `swiftlint lint --strict` runs
   over `Tests/` as well.

## Conventions (match the existing suites)

```swift
import Testing
import Foundation
@testable import SwiftTemplate

@Suite("HPC")
struct HPCTests {
    @Test func simdDot() {
        #expect(SIMDOps.dot(a, b) == 5.0)
    }

    @Test func asyncWork() async throws {
        let result = try await StructuredConcurrency.parallelMap([1, 2]) { $0 * 2 }
        #expect(result == [2, 4])
    }
}
```

- Suites are `struct`s named `<Area>Tests` with a short `@Suite("Name")` label;
  test functions are lowerCamelCase with no `test` prefix.
- Error assertions: `#expect(throws: (any Error).self) { try ... }`, or a
  specific error type when the API documents one.
- Float comparisons use explicit tolerances (`abs(x - expected) < 1e-12`).
- Async code is tested with `async` test functions and awaited results — never
  sleeps, timing races, or polling.
- Temp files: unique names under `NSTemporaryDirectory()` +
  `UUID().uuidString`, cleaned up with `defer { try? FileManager.default.removeItem(...) }`.
  Never write into the repo or `$HOME`.
- Platform-dependent tests are guarded the same way as the code under test
  (`#if canImport(Accelerate)`, skip when `GPUContext()` is `nil`). The CLI test
  file wraps everything in `#if canImport(Testing)`.
- CLI commands are tested by parsing, not spawning processes:
  `try GreetCommand.parse(["Alice", "--count", "3"])` then `#expect` on fields;
  `run()` gets a smoke test where output side effects are acceptable.

## Running

```bash
swift test                                   # everything
swift test --filter HPCTests                 # one suite
swift test --filter HPCTests/simdDot         # one test
swift test --enable-code-coverage --parallel # CI-equivalent
```
