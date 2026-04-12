# Third-Party Library Integration Guide

## SPM Dependency Management

### Adding Dependencies

```swift
// Package.swift
let package = Package(
    name: "MyApp",
    dependencies: [
        // Exact version
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.3.0"),
        // Version range
        .package(url: "https://github.com/apple/swift-log", from: "1.5.0"),
        // Branch-based (for development)
        .package(url: "https://github.com/apple/swift-collections", branch: "main"),
        // Local package
        .package(path: "../MyLocalPackage"),
    ],
    targets: [
        .target(name: "MyApp", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "Logging", package: "swift-log"),
            // Conditional dependency — only on Apple platforms
            .product(name: "Collections", package: "swift-collections",
                     condition: .when(platforms: [.macOS, .iOS])),
        ]),
    ]
)
```

### Version Pinning

- `Package.resolved` locks exact versions — commit it for apps, omit for libraries.
- Use `swift package update` to refresh, `swift package resolve` to restore.
- Prefer `from:` for semver ranges; use `exact:` only when necessary.

### Binary Targets

```swift
.binaryTarget(
    name: "MyFramework",
    url: "https://example.com/MyFramework-1.0.0.xcframework.zip",
    checksum: "abc123..."
)
// Or local:
.binaryTarget(name: "MyFramework", path: "Frameworks/MyFramework.xcframework")
```

### Build Plugins

```swift
.plugin(name: "SwiftLintPlugin", capability: .buildTool()),
// Usage:
.target(name: "MyApp", plugins: [
    .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
])
```

---

## Recommended Packages by Category

### Apple Official
| Package | Use Case |
|---------|----------|
| [swift-argument-parser](https://github.com/apple/swift-argument-parser) | CLI argument parsing |
| [swift-collections](https://github.com/apple/swift-collections) | Deque, OrderedSet, OrderedDictionary |
| [swift-algorithms](https://github.com/apple/swift-algorithms) | Sequence/Collection algorithms |
| [swift-log](https://github.com/apple/swift-log) | Structured logging API |
| [swift-metrics](https://github.com/apple/swift-metrics) | Metrics API |
| [swift-nio](https://github.com/apple/swift-nio) | Event-driven networking |
| [swift-protobuf](https://github.com/apple/swift-protobuf) | Protocol Buffers |
| [swift-crypto](https://github.com/apple/swift-crypto) | Cryptographic operations |

### Networking & Server
| Package | Use Case |
|---------|----------|
| [Vapor](https://github.com/vapor/vapor) | Server-side web framework |
| [Alamofire](https://github.com/Alamofire/Alamofire) | HTTP networking (UIKit apps) |
| [Moya](https://github.com/Moya/Moya) | Network abstraction layer |
| [GRPC Swift](https://github.com/grpc/grpc-swift) | gRPC client/server |

### Data & Persistence
| Package | Use Case |
|---------|----------|
| [GRDB](https://github.com/groue/GRDB.swift) | SQLite toolkit |
| [Realm](https://github.com/realm/realm-swift) | Mobile database |
| [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) | Keychain wrapper |

### Testing
| Package | Use Case |
|---------|----------|
| [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) | Snapshot testing |
| [swift-custom-dump](https://github.com/pointfreeco/swift-custom-dump) | Better test diffs |
| [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs) | Network stubbing |

### UI (Apple Platforms)
| Package | Use Case |
|---------|----------|
| [Kingfisher](https://github.com/onevcat/Kingfisher) | Image loading/caching |
| [SnapKit](https://github.com/SnapKit/SnapKit) | Auto Layout DSL |
| [Lottie](https://github.com/airbnb/lottie-ios) | Animation rendering |

---

## Integration Patterns

### Protocol Abstraction

Never couple your code directly to a third-party type. Define a protocol, then conform the library type in an extension:

```swift
// Your protocol
protocol HTTPClient: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

// Default: URLSession
extension URLSession: HTTPClient {}

// Swap in Alamofire, mock, etc. without changing call sites
```

### Dependency Injection via Environment

```swift
struct Dependencies: Sendable {
    var httpClient: any HTTPClient
    var logger: any LogHandler
    static let live = Dependencies(
        httpClient: URLSession.shared,
        logger: StreamLogHandler.standardOutput(label: "app")
    )
}
```

### Conditional Compilation for Optional Deps

```swift
#if canImport(Vapor)
import Vapor
extension MyService: Content {}
#endif
```

See `Sources/SwiftTemplate/ThirdPartyPatterns.swift` for compilable examples.

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [EXTENDING.md](EXTENDING.md) · [TUTORIAL.md](TUTORIAL.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
