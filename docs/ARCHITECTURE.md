# Architecture

This document describes the project structure, target relationships, and design patterns used in the SwiftTemplate project.

## Project Structure

```
SwiftTemplate/
├── Package.swift                        # SPM manifest (swift-tools-version: 5.9)
├── Package.resolved                     # Pinned dependency versions
├── Makefile                             # Build, test, and security scan shortcuts
├── .swiftlint.yml                       # SwiftLint configuration (security-focused)
├── .github/workflows/security.yml       # CI: security scanning on macOS + Linux
├── scripts/
│   └── security-scan.sh                 # Runs SwiftLint, audit, Periphery, Trivy
├── Sources/
│   ├── SwiftTemplate/                   # Main library target
│   │   ├── SwiftTemplate.swift          # Module entry point (version constant)
│   │   ├── BestPractices.swift          # Protocol-oriented design, COW, typed errors
│   │   ├── CrossPlatform.swift          # Platform detection, conditional compilation
│   │   ├── ThirdPartyPatterns.swift     # Dependency abstraction (HTTP, logging, DI)
│   │   ├── Concurrency/                 # GCD, async/await, actors, TaskGroups
│   │   ├── Rendering/                   # Metal pipelines, Core Graphics, SwiftUI canvas
│   │   ├── Systems/                     # File I/O, processes, memory management
│   │   ├── HPC/                         # SIMD, Accelerate, parallel algorithms
│   │   ├── Simulation/                  # Numerical integration, physics engines
│   │   └── SwiftTemplate.docc/          # DocC catalog (articles, tutorials)
│   ├── SwiftTemplateCLI/                # CLI executable target
│   │   ├── SwiftTemplateCLI.swift       # Root command (AsyncParsableCommand)
│   │   ├── GreetCommand.swift           # Subcommand: greet
│   │   ├── GenerateCommand.swift        # Subcommand: generate
│   │   ├── FetchCommand.swift           # Subcommand: fetch
│   │   ├── ConfigCommand.swift          # Subcommand: config
│   │   ├── PipeCommand.swift            # Subcommand: pipe
│   │   ├── FormatCommand.swift          # Subcommand: format
│   │   └── PlatformCommand.swift        # Subcommand: platform
│   └── SwiftTemplateExample/            # Minimal example executable
│       └── main.swift
├── Tests/
│   ├── SwiftTemplateTests/              # Unit + integration tests for the library
│   └── SwiftTemplateCLITests/           # Tests for CLI commands
├── docs/                                # Markdown guides (this directory)
└── examples/                            # Standalone example files
```

## Targets & Products

### Products

| Product | Type | Target | Description |
|---------|------|--------|-------------|
| `SwiftTemplate` | Library | `SwiftTemplate` | Core library — all modules |
| `SwiftTemplateExample` | Executable | `SwiftTemplateExample` | Minimal usage demo |
| `SwiftTemplateCLI` | Executable | `SwiftTemplateCLI` | Full CLI with subcommands |

### Dependency Graph

```
SwiftTemplateCLI
├── SwiftTemplate
└── ArgumentParser (swift-argument-parser 1.5+)

SwiftTemplateExample
└── SwiftTemplate

SwiftTemplateTests
└── SwiftTemplate

SwiftTemplateCLITests
└── SwiftTemplateCLI
        ├── SwiftTemplate
        └── ArgumentParser

SwiftTemplate
└── (no target dependencies)
    Plugins: SwiftLintBuildToolPlugin (SwiftLintPlugins 0.58+)
    Build plugins: swift-docc-plugin 1.4.3+
```

### Platform Support

Declared in `Package.swift`:

- macOS 14+
- iOS 17+
- tvOS 17+
- watchOS 10+
- visionOS 1+
- Linux (via conditional compilation)

## Module Architecture

The `SwiftTemplate` library is organized into domain-specific subdirectories. Each subdirectory contains a single Swift file that demonstrates patterns for that domain.

```
SwiftTemplate (library)
│
├── Core
│   ├── SwiftTemplate.swift        — Version constant, module namespace
│   ├── BestPractices.swift        — Reusable patterns (protocols, COW, errors)
│   ├── CrossPlatform.swift        — Platform abstraction layer
│   └── ThirdPartyPatterns.swift   — External dependency abstractions
│
└── Domain Modules
    ├── Concurrency/               — Async patterns, actors, structured concurrency
    ├── Rendering/                 — GPU pipelines, 2D/3D graphics
    ├── Systems/                   — OS interfaces, file I/O, processes
    ├── HPC/                       — SIMD, Accelerate, parallel compute
    └── Simulation/                — Physics, numerical methods
```

All domain modules live within the single `SwiftTemplate` target — they are subdirectories, not separate SPM targets. This keeps the dependency graph simple while organizing code by domain.

## Design Patterns

### Protocol-Oriented Design
Types conform to focused protocols (`Steppable`, `EnergyReporting`, `HTTPClient`, `Logger`) enabling composition and testability. Default implementations are provided via protocol extensions.

### Value Types with Copy-on-Write
`COWBuffer<Element>` demonstrates reference-counted storage with `isKnownUniquelyReferenced` to avoid unnecessary copies — the same pattern used by `Array` and `Data` in the standard library.

### Typed Error Handling
`Config` uses Swift 5.9 typed throws (`throws(ConfigError)`) so callers know exactly which errors to handle without consulting documentation.

### Property Wrappers
`@Clamped` constrains values to a range at the point of assignment, eliminating scattered validation logic.

### Dependency Injection
`AppDependencies` is a lightweight DI container holding protocol-typed services. Production code uses `.live`; tests swap in mocks.

### Command Pattern (CLI)
`SwiftTemplateCLI` uses `swift-argument-parser`'s `AsyncParsableCommand` with subcommands, demonstrating `@Argument`, `@Option`, `@Flag`, and validation.

### Conditional Compilation
`CrossPlatform.swift` uses `#if os(...)`, `#if canImport(...)`, and `#if arch(...)` to provide a unified API across Apple platforms and Linux.

## Build Settings

The `SwiftTemplate` target enables `StrictConcurrency` as an experimental feature, enforcing `Sendable` checking across the library. This catches data-race issues at compile time.

## CI / Security

The GitHub Actions workflow (`.github/workflows/security.yml`) runs on every push/PR to `main`:

1. Builds the project on macOS 14 and Ubuntu
2. Runs `scripts/security-scan.sh` which invokes SwiftLint, swift-package-audit, Periphery, and Trivy

See [SecurityScanningGuide.md](SecurityScanningGuide.md) for details on each tool.

## Related Docs

**Core:**
[TOOLCHAIN.md](TOOLCHAIN.md) · [EXTENDING.md](EXTENDING.md) · [TUTORIAL.md](TUTORIAL.md)

**Module Guides:**
[ConcurrencyGuide.md](ConcurrencyGuide.md) · [RenderingGuide.md](RenderingGuide.md) · [SystemsGuide.md](SystemsGuide.md) · [HPCGuide.md](HPCGuide.md) · [SimulationGuide.md](SimulationGuide.md)

**Reference:**
[BestPractices.md](BestPractices.md) · [CLIGuide.md](CLIGuide.md) · [TestingGuide.md](TestingGuide.md) · [CrossPlatformGuide.md](CrossPlatformGuide.md) · [ThirdPartyGuide.md](ThirdPartyGuide.md) · [SecurityScanningGuide.md](SecurityScanningGuide.md) · [DocumentationGuide.md](DocumentationGuide.md)
