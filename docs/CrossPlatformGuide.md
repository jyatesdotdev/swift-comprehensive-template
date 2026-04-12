# Cross-Platform Swift Development Guide

## Overview

Swift runs on macOS, iOS, tvOS, watchOS, visionOS, Linux, and Windows. This module demonstrates patterns for writing portable code that adapts to each platform.

See `Sources/SwiftTemplate/CrossPlatform.swift` for all implementations.

## Key Patterns

### 1. Conditional Compilation

Swift provides several compile-time directives:

```swift
#if os(macOS)          // Target OS
#if arch(arm64)        // CPU architecture
#if canImport(Metal)   // Framework availability
#if targetEnvironment(simulator)  // Simulator vs device
#if DEBUG              // Build configuration
```

Use `canImport()` over `os()` when possible — it's more precise and future-proof.

### 2. Platform Detection (`Platform`)

- `Platform.current` — compile-time OS enum
- `Platform.isApple` — true on any Darwin platform
- `Platform.architecture` — "arm64", "x86_64", etc.

### 3. Portable Paths (`PortablePath`)

- `PortablePath.home` — uses `NSHomeDirectory()` on Apple, `$HOME` on Linux
- `PortablePath.temp` — `NSTemporaryDirectory()` (works everywhere via Foundation)
- `PortablePath.join("a", "b", "c")` — portable path joining

### 4. Platform-Abstracted Logging (`PlatformLogger`)

Uses `os.Logger` on Apple platforms for structured logging with system integration. Falls back to stderr on Linux/Windows.

```swift
PlatformLogger.log(.info, "Server started on port \(port)")
```

### 5. Feature Flags (`FeatureFlags`)

Compile-time booleans for optional framework availability:

- `FeatureFlags.hasGPU` — Metal available
- `FeatureFlags.hasSwiftUI` — SwiftUI available
- `FeatureFlags.hasCombine` — Combine available

### 6. Byte Order (`ByteOrder`)

Portable endianness handling for binary protocols:

```swift
let bytes = ByteOrder.toBigEndian(0xDEADBEEF)  // Network byte order
let value = ByteOrder.fromBigEndian(bytes)       // Back to host order
```

### 7. Networking (`PortableHTTP`)

`URLSession` works on all platforms (via swift-corelibs-foundation on Linux):

```swift
let data = try await PortableHTTP.get(url: myURL)
```

## Best Practices

1. **Prefer `canImport` over `os`** — checks actual availability, not just platform
2. **Guard Apple-only code** — wrap UIKit/AppKit/Metal in `#if canImport()`
3. **Use Foundation** — it's available everywhere via swift-corelibs-foundation
4. **Test on Linux** — use Docker or Swift on Server to catch portability issues
5. **Avoid `@objc`** — not available on Linux; use protocols instead
6. **Use `@available` for version checks** — runtime API availability on Apple platforms
7. **Separate platform-specific code** — keep portable logic in its own files

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TUTORIAL.md](TUTORIAL.md) · [EXTENDING.md](EXTENDING.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
