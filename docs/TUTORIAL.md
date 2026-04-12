# Tutorial: Getting Started with SwiftTemplate

A hands-on walkthrough for new developers — from cloning to shipping a feature.

> **Time estimate:** ~20 minutes
>
> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TOOLCHAIN.md](TOOLCHAIN.md) · [EXTENDING.md](EXTENDING.md)

---

## 1. Prerequisites

| Tool | Minimum Version | Install |
|------|----------------|---------|
| Swift | 5.9+ | Bundled with Xcode or [swift.org/install](https://swift.org/install) |
| Xcode | 15+ (macOS only) | Mac App Store |
| SwiftLint | 0.58+ | `brew install swiftlint` |

Verify your setup:

```bash
swift --version   # Swift version 5.9 or later
swiftlint version # Optional — needed for linting
```

For the full tool list (Periphery, Trivy, swift-format, etc.), see [TOOLCHAIN.md](TOOLCHAIN.md).

## 2. Clone & Build

```bash
git clone <repository-url> SwiftTemplate
cd SwiftTemplate

# Resolve dependencies and build all targets
swift build
```

The first build fetches SPM dependencies (swift-argument-parser, swift-docc-plugin, SwiftLintPlugins) and compiles three products:

| Product | Type | Description |
|---------|------|-------------|
| `SwiftTemplate` | Library | Core modules (Concurrency, Rendering, Systems, HPC, Simulation) |
| `SwiftTemplateExample` | Executable | Minimal demo of library usage |
| `SwiftTemplateCLI` | Executable | Full CLI with subcommands via ArgumentParser |

## 3. Run the Example

```bash
swift run SwiftTemplateExample
```

Expected output:

```
SwiftTemplate v0.1.0
A comprehensive Swift template for systems, HPC, rendering, and more.
```

## 4. Explore the CLI

The CLI demonstrates real-world ArgumentParser patterns:

```bash
# See all subcommands
swift run SwiftTemplateCLI --help

# Greet someone
swift run SwiftTemplateCLI greet World

# Greet with options
swift run SwiftTemplateCLI greet Alice --greeting Hi --shout --count 3

# Check version
swift run SwiftTemplateCLI --version
```

Available subcommands: `greet`, `generate`, `fetch`, `config`, `pipe`, `format`, `platform`.

## 5. Run Tests

```bash
# Run all tests
swift test

# Verbose output
swift test --verbose

# Filter to a specific test
swift test --filter SwiftTemplateTests
swift test --filter SwiftTemplateCLITests
```

The project has two test targets:

- `SwiftTemplateTests` — unit, performance, and integration tests for the library
- `SwiftTemplateCLITests` — tests for CLI commands

## 6. Run Linters

### SwiftLint (via Makefile)

```bash
make lint
```

This runs `swiftlint lint --strict` against `Sources/` and `Tests/` using the project's `.swiftlint.yml`. Security-sensitive rules (`force_cast`, `force_try`, `force_unwrapping`, `empty_catch`) are promoted to errors.

### SwiftLint (via SPM build plugin)

SwiftLint also runs automatically during `swift build` for the `SwiftTemplate` target via the `SwiftLintBuildToolPlugin`.

## 7. Run Security Scans

```bash
# Run all available security tools
make security

# Or run individual tools
make audit      # swift-package-audit — dependency vulnerabilities
make analyze    # Xcode static analyzer (macOS only)
make periphery  # Dead code detection
make trivy      # Filesystem/dependency vulnerability scan
```

The script at `scripts/security-scan.sh` auto-skips tools that aren't installed and reports a summary. See [SecurityScanningGuide.md](SecurityScanningGuide.md) for details.

## 8. Add a Feature (Walkthrough)

Let's add a `MathUtils` type to the library with a single function.

### Step 1 — Create the source file

Create `Sources/SwiftTemplate/MathUtils.swift`:

```swift
/// Mathematical utility functions.
public enum MathUtils {
    /// Clamps a value to a closed range.
    ///
    /// - Parameters:
    ///   - value: The value to clamp.
    ///   - range: The allowed range.
    /// - Returns: The clamped value.
    public static func clamp<T: Comparable>(_ value: T, to range: ClosedRange<T>) -> T {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
```

No changes to `Package.swift` needed — SPM auto-discovers files in existing targets.

### Step 2 — Add a test

Add to `Tests/SwiftTemplateTests/SwiftTemplateTests.swift` (or create a new file in that directory):

```swift
import Testing
@testable import SwiftTemplate

@Test func mathUtilsClamp() {
    #expect(MathUtils.clamp(5, to: 0...10) == 5)
    #expect(MathUtils.clamp(-1, to: 0...10) == 0)
    #expect(MathUtils.clamp(99, to: 0...10) == 10)
}
```

### Step 3 — Build, test, lint

```bash
swift build
swift test --filter mathUtilsClamp
make lint
```

All three should pass. You've added a feature end-to-end.

> **Going further:** To add a new module, executable, or SPM dependency, see [EXTENDING.md](EXTENDING.md).

## 9. Generate Documentation

```bash
# Build DocC documentation
swift package generate-documentation --target SwiftTemplate

# Preview in browser
swift package preview-documentation --target SwiftTemplate
```

DocC articles live in `Sources/SwiftTemplate/SwiftTemplate.docc/`. See [DocumentationGuide.md](DocumentationGuide.md).

## 10. Build for Release

```bash
swift build -c release
```

Release binaries are placed in `.build/release/`. For cross-platform considerations, see [CrossPlatformGuide.md](CrossPlatformGuide.md).

---

## Quick Reference

| Task | Command |
|------|---------|
| Build | `swift build` |
| Test | `swift test` |
| Run example | `swift run SwiftTemplateExample` |
| Run CLI | `swift run SwiftTemplateCLI --help` |
| Lint | `make lint` |
| Security scan | `make security` |
| Clean | `make clean` |
| Docs | `swift package generate-documentation --target SwiftTemplate` |
| Release build | `swift build -c release` |

## Next Steps

- [ARCHITECTURE.md](ARCHITECTURE.md) — understand the module structure and design patterns
- [TOOLCHAIN.md](TOOLCHAIN.md) — set up your editor and optional tools
- [EXTENDING.md](EXTENDING.md) — add modules, executables, and dependencies
- [BestPractices.md](BestPractices.md) — coding conventions and patterns
- [ConcurrencyGuide.md](ConcurrencyGuide.md) — async/await and actor patterns
