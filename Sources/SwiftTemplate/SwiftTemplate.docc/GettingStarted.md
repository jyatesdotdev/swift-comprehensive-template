# Getting Started with SwiftTemplate

Set up the template, build across platforms, and explore the modules.

## Overview

SwiftTemplate is a Swift Package Manager project targeting macOS 14+, iOS 17+, tvOS 17+, watchOS 10+, and visionOS 1+. It also compiles on Linux where Apple-specific frameworks are unavailable.

## Add as a Dependency

Add SwiftTemplate to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/SwiftTemplate.git", from: "0.1.0")
]
```

Then add it to your target:

```swift
.target(name: "YourTarget", dependencies: ["SwiftTemplate"])
```

## Build and Test

```bash
# Build
swift build

# Run tests
swift test

# Run the example executable
swift run SwiftTemplateExample
```

## Generate Documentation

Build DocC documentation locally:

```bash
# Generate documentation archive
swift package generate-documentation --target SwiftTemplate

# Preview in browser
swift package --disable-sandbox preview-documentation --target SwiftTemplate
```

## Explore the Modules

Import the library and use any module:

```swift
import SwiftTemplate

// Concurrency — actors
let counter = Counter()
await counter.increment()

// Simulation — particle physics
var system = ParticleSystem()
system.addParticle(Particle(position: Vec2(x: 0, y: 10)))
system.step(dt: 1.0 / 60.0)

// HPC — parallel processing
let results = await ParallelProcessing.concurrentMap(Array(0..<100)) { $0 * $0 }
```

## Cross-Platform Considerations

Use conditional compilation for platform-specific code:

```swift
#if canImport(Metal)
// Metal compute pipelines
#endif

#if canImport(CoreGraphics)
// Core Graphics drawing
#endif

#if os(Linux)
// Linux-specific paths
#endif
```

See ``Platform`` and ``FeatureFlags`` for runtime and compile-time detection helpers.
