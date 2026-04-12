# Extending the Template

How to add new modules, executables, dependencies, lint rules, and test targets.

> See also: [ARCHITECTURE.md](ARCHITECTURE.md) for project structure, [TOOLCHAIN.md](TOOLCHAIN.md) for tool setup.

## Adding a New Module (Library Target)

1. Create the source directory:

```bash
mkdir -p Sources/Networking
```

2. Add at least one Swift file:

```swift
// Sources/Networking/NetworkClient.swift

/// A client for making HTTP requests.
public struct NetworkClient {
    /// Creates a new client.
    public init() {}
}
```

3. Register the target in `Package.swift`:

```swift
// In the `targets` array:
.target(
    name: "Networking",
    path: "Sources/Networking",
    swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency")
    ],
    plugins: [
        .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
    ]
),
```

4. Optionally expose it as a product (for external consumers):

```swift
// In the `products` array:
.library(name: "Networking", targets: ["Networking"]),
```

5. To depend on it from an existing target, add it to that target's `dependencies`:

```swift
.target(
    name: "SwiftTemplate",
    dependencies: ["Networking"],
    // ...
),
```

6. Verify: `swift build`

### Checklist for new modules

- [ ] `StrictConcurrency` enabled in `swiftSettings`
- [ ] `SwiftLintBuildToolPlugin` added to `plugins`
- [ ] Source path under `Sources/` matches the `path` parameter
- [ ] All public types have `///` doc comments

## Adding a New Executable

1. Create the source directory with an entry point:

```bash
mkdir -p Sources/MyTool
```

```swift
// Sources/MyTool/MyTool.swift
import SwiftTemplate
import ArgumentParser

@main
struct MyTool: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A custom tool built on SwiftTemplate."
    )

    func run() throws {
        print("Hello from MyTool")
    }
}
```

2. Register in `Package.swift`:

```swift
// Product:
.executable(name: "MyTool", targets: ["MyTool"]),

// Target:
.executableTarget(
    name: "MyTool",
    dependencies: [
        "SwiftTemplate",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ],
    path: "Sources/MyTool"
),
```

3. Build and run:

```bash
swift build
swift run MyTool
```

> **Note:** Use `@main` with `ParsableCommand` (from ArgumentParser) or a plain `@main` struct. Alternatively, use a `main.swift` file — see `Sources/SwiftTemplateExample/main.swift` for an example without ArgumentParser.

## Adding a Dependency via SPM

1. Add the package to the top-level `dependencies` array in `Package.swift`:

```swift
dependencies: [
    // Existing dependencies...
    .package(url: "https://github.com/apple/swift-log", from: "1.5.0"),
],
```

2. Add the product to the target(s) that need it:

```swift
.target(
    name: "SwiftTemplate",
    dependencies: [
        .product(name: "Logging", package: "swift-log"),
    ],
    // ...
),
```

3. Resolve and build:

```bash
swift package resolve
swift build
```

### Pinning versions

- `from: "1.5.0"` — minimum version, allows compatible updates (recommended)
- `exact: "1.5.0"` — exact version only
- `.upToNextMinor(from: "1.5.0")` — allows patch updates only
- `branch: "main"` — track a branch (avoid in production)

After resolving, commit `Package.resolved` to lock dependency versions.

## Adding SwiftLint Rules

The project configures SwiftLint in `.swiftlint.yml`. Rules fall into three categories:

### Enable an opt-in rule

Add it to the `opt_in_rules` list:

```yaml
opt_in_rules:
  - force_unwrapping
  - implicitly_unwrapped_optional
  - fatal_error_message
  - empty_catch
  - discouraged_optional_boolean
  - private_over_fileprivate
  - closure_body_length          # ← new rule
```

### Promote a rule to error severity

Add a top-level entry to fail CI on violations:

```yaml
closure_body_length:
  severity: error
```

### Adjust thresholds

Modify warning/error limits for existing rules:

```yaml
line_length:
  warning: 120    # characters before warning
  error: 200      # characters before error
```

### Verify

```bash
# Run SwiftLint standalone:
swiftlint lint --config .swiftlint.yml

# Or via Makefile:
make lint

# SwiftLint also runs automatically during `swift build` via the build plugin.
```

> **Tip:** Run `swiftlint rules` to list all available rules and their default configuration.

## Adding a New Test Target

1. Create the test directory:

```bash
mkdir -p Tests/NetworkingTests
```

2. Add a test file:

```swift
// Tests/NetworkingTests/NetworkingTests.swift
import Testing
@testable import Networking

@Suite("Networking Tests")
struct NetworkingTests {
    @Test("Client initializes")
    func clientInit() {
        let client = NetworkClient()
        #expect(client != nil)
    }
}
```

3. Register in `Package.swift`:

```swift
.testTarget(
    name: "NetworkingTests",
    dependencies: ["Networking"],
    path: "Tests/NetworkingTests"
),
```

4. Run:

```bash
# All tests:
swift test

# Specific test target:
swift test --filter NetworkingTests

# Via Makefile:
make test
```

### Test conventions

- This template uses Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`) — not XCTest
- Test target names follow the pattern `<ModuleName>Tests`
- Test files go in `Tests/<TargetName>/`
- Use `@testable import` to access internal symbols

## Quick Reference

| Task | Key files to modify |
|---|---|
| New library module | `Package.swift` (target + optional product), `Sources/<Name>/` |
| New executable | `Package.swift` (target + product), `Sources/<Name>/` |
| New dependency | `Package.swift` (package dependency + target dependency) |
| New lint rule | `.swiftlint.yml` |
| New test target | `Package.swift` (testTarget), `Tests/<Name>/` |
