# Swift Comprehensive Template

A cross-platform Swift project template demonstrating modern Swift capabilities beyond iOS development — covering systems programming, high-performance computing, rendering pipelines, concurrency, and simulation.

## Requirements

- Swift 5.9+
- Xcode 15+ (for Apple platforms)
- macOS 14+ / iOS 17+ / Linux (Ubuntu 22.04+)

## Project Structure

```
SwiftTemplate/
├── Package.swift                    # SPM manifest with multi-platform targets
├── Sources/
│   ├── SwiftTemplate/              # Main library
│   │   ├── SwiftTemplate.swift     # Module entry point & exports
│   │   ├── Concurrency/           # GCD, async/await, actors, structured concurrency
│   │   ├── Rendering/             # Metal, Core Graphics, SwiftUI graphics
│   │   ├── Systems/               # Foundation, Core Foundation, file I/O, processes
│   │   ├── HPC/                   # SIMD, Accelerate, parallel processing
│   │   └── Simulation/            # Numerical computing, physics, Core Animation
│   └── SwiftTemplateExample/      # Executable demonstrating library usage
├── Tests/
│   └── SwiftTemplateTests/        # XCTest: unit, performance, and integration tests
├── docs/                           # DocC documentation and guides
└── examples/                       # Standalone example files
```

## Building

```bash
# Build all targets
swift build

# Build for release
swift build -c release

# Run the example
swift run SwiftTemplateExample

# Run tests
swift test

# Run tests with verbose output
swift test --verbose
```

## Modules

| Module | Description |
|--------|-------------|
| **Concurrency** | GCD, async/await, actors, TaskGroups, structured concurrency patterns |
| **Rendering** | Metal pipeline setup, Core Graphics drawing, SwiftUI canvas |
| **Systems** | File I/O, process management, memory management, system interfaces |
| **HPC** | SIMD operations, Accelerate framework, parallel algorithms |
| **Simulation** | Numerical integration, physics engines, Core Animation |

## Cross-Platform Support

This template uses conditional compilation for platform-specific APIs:

```swift
#if canImport(Metal)
import Metal  // Apple GPU programming
#endif

#if canImport(Foundation)
import Foundation  // Available on Apple + Linux via swift-corelibs
#endif

#if os(Linux)
import Glibc
#elseif os(macOS) || os(iOS)
import Darwin
#endif
```

## Documentation

### Getting Started

| Guide | Description |
|-------|-------------|
| [Tutorial](docs/TUTORIAL.md) | New developer walkthrough — clone, build, test, add a feature |
| [Architecture](docs/ARCHITECTURE.md) | Project structure, targets, dependency graph, design patterns |
| [Toolchain](docs/TOOLCHAIN.md) | Required tools, installation (macOS/Linux), editor setup |
| [Extending](docs/EXTENDING.md) | Adding modules, executables, dependencies, lint rules, tests |

### Module Guides

| Guide | Description |
|-------|-------------|
| [Concurrency](docs/ConcurrencyGuide.md) | GCD, async/await, actors, structured concurrency |
| [Rendering](docs/RenderingGuide.md) | Metal, Core Graphics, SwiftUI canvas |
| [Systems](docs/SystemsGuide.md) | File I/O, processes, memory, POSIX interfaces |
| [HPC](docs/HPCGuide.md) | SIMD, Accelerate, parallel algorithms |
| [Simulation](docs/SimulationGuide.md) | Numerical integration, physics, Core Animation |

### Reference

| Guide | Description |
|-------|-------------|
| [Best Practices](docs/BestPractices.md) | Swift idioms, patterns, and conventions |
| [CLI Guide](docs/CLIGuide.md) | ArgumentParser patterns and CLI development |
| [Testing](docs/TestingGuide.md) | Swift Testing, XCTest, performance benchmarks |
| [Cross-Platform](docs/CrossPlatformGuide.md) | Conditional compilation, portability patterns |
| [Third-Party](docs/ThirdPartyGuide.md) | Dependency abstraction and SPM integration |
| [Security Scanning](docs/SecurityScanningGuide.md) | SwiftLint, audit, Periphery, Trivy |
| [Documentation](docs/DocumentationGuide.md) | DocC setup, writing, and publishing |

## License

MIT
