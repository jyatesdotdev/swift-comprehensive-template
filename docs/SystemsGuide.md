# Systems Programming Guide

Swift provides powerful systems programming capabilities through Foundation, Core Foundation, and direct POSIX interfaces.

## File System Operations

`FileSystem` wraps `FileManager` with typed errors and convenience methods:

```swift
// Read/write
let data = try FileSystem.readData(at: "/tmp/input.bin")
try FileSystem.write(data, to: "/tmp/output.bin")

// Atomic write (temp file + rename)
try FileSystem.atomicWrite(data, to: "/tmp/safe.bin")

// Directory traversal
let entries = try FileSystem.listDirectory(at: "/tmp")
let allFiles = try FileSystem.walk("/usr/local")
```

## Environment & System Info

```swift
let home = SystemEnvironment.get("HOME")
let cpus = SystemEnvironment.processorCount
let ram  = SystemEnvironment.physicalMemory
```

## Process Management (macOS/Linux)

```swift
let result = Shell.sh("ls -la /tmp")
print(result.stdout)

// Async variant
let r = await Shell.runAsync("/usr/bin/git", arguments: ["status"])
```

## Streaming I/O

Read large files in chunks without loading everything into memory:

```swift
try StreamIO.readChunked(path: "/tmp/large.bin", chunkSize: 4096) { chunk in
    process(chunk)
}
```

## Unsafe Memory

Safe wrappers around pointer operations:

```swift
UnsafeMemory.withManualBuffer(of: Float.self, count: 1024) { buffer in
    for i in buffer.indices { buffer[i] = Float(i) }
}

// Reinterpret bytes
let floats: [Float] = UnsafeMemory.reinterpret(byteArray, as: Float.self)
```

## Core Foundation Bridging

Swift types toll-free bridge to CF counterparts:

```swift
let s = CFBridging.cfStringRoundTrip("hello")  // String → CFString → String
```

## Signal Handling

POSIX signals via `Darwin`/`Glibc`:

```swift
Signals.trap(SIGINT) { _ in print("interrupted") }
Signals.ignore(SIGPIPE)
```

## Key Patterns

- Use `FileSystem.atomicWrite` for crash-safe persistence
- Prefer `StreamIO.readChunked` for files larger than available memory
- Guard platform-specific APIs with `#if os(macOS)` or `#if canImport()`
- Always `defer { ptr.deallocate() }` when using manual memory
- Use `Unmanaged` to pass Swift objects through C callback contexts

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TUTORIAL.md](TUTORIAL.md) · [CrossPlatformGuide.md](CrossPlatformGuide.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
