# Testing Guide

## Overview

SwiftTemplate uses **Swift Testing** (`import Testing`) exclusively — `@Suite`,
`@Test`, and `#expect`. XCTest is not used anywhere in this repository and must
not be reintroduced. Swift Testing requires a Swift 6 / Xcode 16.2+ toolchain
(CI pins Xcode 16.2).

CI runs `./scripts/check-coverage.sh`, which executes
`swift test --enable-code-coverage --parallel` and enforces a **minimum of 80%
line coverage** over the core library and CLI. Excluded from the gate: `Tests/`,
`.build/`, `SwiftTemplateUI`, `SwiftTemplateUIDemo`, and `SwiftTemplateExample`.
New public API on the gated targets needs accompanying tests.

## Running Tests

```bash
swift test                                   # Build and run all tests
swift test --filter SimulationTests          # Run a specific suite
swift test --filter HPCTests/simdDot         # Run a single test
swift test --enable-code-coverage --parallel # CI-equivalent run
```

## Test Structure

Test files mirror the source layout: `Sources/SwiftTemplate/HPC/HPC.swift` is
tested by `Tests/SwiftTemplateTests/HPCTests.swift`; CLI commands are tested in
`Tests/SwiftTemplateCLITests/SwiftTemplateCLITests.swift`; UI view-model logic
is tested in `Tests/SwiftTemplateUITests/SwiftTemplateUITests.swift`.

```swift
import Testing
import Foundation
@testable import SwiftTemplate

@Suite("MyFeature")
struct MyFeatureTests {
    @Test func basicBehavior() {
        #expect(1 + 1 == 2)
    }

    @Test func throwingFunction() {
        let config = Config([:])
        #expect(throws: ConfigError.self) { try config.require("missing") }
    }

    @Test func asyncBehavior() async {
        let counter = Counter(0)
        #expect(await counter.increment() == 1)
    }
}
```

### Platform-Conditional Tests

Guard platform-dependent tests the same way as the code under test:

```swift
#if canImport(Accelerate)
@Test func vectorAdd() {
    #expect(AccelerateOps.vectorAdd([1, 2], [3, 4]) == [4, 6])
}
#endif
```

For hardware that may be absent (e.g. GPU on CI runners), probe and return
early instead of failing:

```swift
@Test func gpuDoubling() throws {
    guard let context = MetalRendering.GPUContext() else { return } // no GPU
    let out = try MetalRendering.doubleArray([1, 2], context: context)
    #expect(out == [2, 4])
}
```

## Test Categories

### Unit Tests
- **BestPractices**: Point2D equality, COWBuffer copy-on-write, Config typed throws, Clamped property wrapper
- **Simulation**: Vec2 arithmetic/normalization, Euler/RK4 integrators, trapezoidal integration, AABB overlap, particle ground collision, spring relaxation
- **HPC**: SIMD operations, batch dot product, concurrent map/reduce, aligned buffers

### Async Tests
- Actor isolation (Counter, Cache)
- TaskGroup-based parallel map
- Throttled concurrency

### CLI Tests
- Parse without executing: `try GreetCommand.parse(["Alice", "--count", "3"])`,
  then `#expect` on the decoded properties
- Validation failures: `#expect(throws: (any Error).self) { try GreetCommand.parse(["Alice", "--count", "0"]) }`
- `run()` smoke tests for output-producing commands

### Performance Checks
- `ContinuousClock().measure {}` with generous sanity thresholds
  (e.g., 100K Vec2 ops < 1 second) — not brittle micro-benchmarks

## Best Practices

1. **Name tests descriptively** — lowerCamelCase function names describing the behavior, no `test` prefix
2. **One assertion per concept** — group related checks, but test distinct behaviors separately
3. **Use tolerances for floating point** — `#expect(abs(result - expected) < 1e-6)`, never `==` on computed floats
4. **Test edge cases** — zero vectors, empty collections, missing keys, boundary values
5. **Async tests await results directly** — no sleeps, polling, or timing races
6. **No force operations** — `!`, `as!`, and `try!` are SwiftLint errors in tests too; use `throws` test functions
7. **Clean up temp files** — unique `NSTemporaryDirectory()` + `UUID` paths, removed in `defer`

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TUTORIAL.md](TUTORIAL.md) · [EXTENDING.md](EXTENDING.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
