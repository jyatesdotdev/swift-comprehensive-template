# Testing Guide

## Overview

SwiftTemplate includes comprehensive tests covering unit testing, async testing, and performance benchmarking using both Swift Testing and XCTest.

## Running Tests

```bash
swift test                    # Build and run all tests
swift test --filter Simulation # Run a specific test suite
swift test --parallel         # Run tests in parallel
```

## Test Structure

### Swift Testing (Primary — Swift 5.9+)

```swift
import Testing
@testable import SwiftTemplate

@Suite("MyFeature")
struct MyFeatureTests {
    @Test func basicBehavior() {
        #expect(1 + 1 == 2)
    }

    @Test func throwingFunction() throws {
        #expect(throws: ConfigError.self) { try config.require("missing") }
    }

    @Test func asyncBehavior() async {
        let counter = Counter(0)
        #expect(await counter.increment() == 1)
    }
}
```

### XCTest (Fallback)

```swift
import XCTest
@testable import SwiftTemplate

final class MyFeatureTests: XCTestCase {
    func testBasic() { XCTAssertEqual(1 + 1, 2) }
    func testAsync() async { /* async tests supported in XCTest too */ }
    func testPerformance() { measure { /* benchmarked code */ } }
}
```

### Conditional Compilation

Use `#if canImport(Testing)` / `#elseif canImport(XCTest)` to support both frameworks in a single file. This ensures tests work across environments (Xcode, SPM CLI, Linux).

## Test Categories

### Unit Tests
- **BestPractices**: Point2D equality, COWBuffer copy-on-write, Config typed throws, Clamped property wrapper
- **Simulation**: Vec2 arithmetic/normalization, Euler/RK4 integrators, trapezoidal integration, AABB overlap, particle ground collision, spring relaxation
- **HPC**: SIMD operations, batch dot product, concurrent map/reduce, aligned buffers

### Async Tests
- Actor isolation (Counter, Cache)
- TaskGroup-based parallel map
- Throttled concurrency

### Performance Tests
- `ContinuousClock.measure {}` for Swift Testing
- `measure {}` for XCTest
- Throughput sanity checks (e.g., 100K Vec2 ops < 1 second)

## UI Testing Patterns (Xcode)

UI tests require an Xcode project with a UI test target. Key patterns:

```swift
import XCTest

final class AppUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() { app.launch() }

    func testNavigation() {
        app.buttons["Start"].tap()
        XCTAssertTrue(app.staticTexts["Welcome"].exists)
    }

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
}
```

## Best Practices

1. **Name tests descriptively** — test function names should describe the behavior being verified
2. **One assertion per concept** — group related checks, but test distinct behaviors separately
3. **Use accuracy for floating point** — `#expect(abs(result - expected) < 1e-6)` or `XCTAssertEqual(_:_:accuracy:)`
4. **Test edge cases** — zero vectors, empty collections, missing keys, boundary values
5. **Async tests** — use `async` test functions directly; avoid `XCTestExpectation` when possible
6. **Performance baselines** — use `measure {}` (XCTest) or `ContinuousClock` (Swift Testing) with sanity thresholds

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TUTORIAL.md](TUTORIAL.md) · [EXTENDING.md](EXTENDING.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
