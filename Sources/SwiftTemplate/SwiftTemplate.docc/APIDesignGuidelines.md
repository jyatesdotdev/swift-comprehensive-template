# API Design Guidelines

Swift API design conventions used throughout this template.

## Overview

These guidelines follow Apple's [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) and extend them with patterns specific to systems and performance-critical code.

## Naming

### Clarity at the Point of Use

Names should read naturally at the call site:

```swift
// Good — reads as English
particles.removeAll(where: { $0.isExpired })
system.step(dt: deltaTime)

// Avoid — unclear at call site
particles.remove(true)
system.advance(0.016)
```

### Mutating vs Non-Mutating

Use the `-ed`/`-ing` convention:

```swift
// Mutating
array.sort()
buffer.append(contentsOf: data)

// Non-mutating — returns new value
let sorted = array.sorted()
let combined = buffer.appending(contentsOf: data)
```

## Protocols

### Name for Capability

Protocols describing capability use `-able`, `-ible`, or `-ing`:

```swift
protocol Steppable { mutating func step(dt: Double) }
protocol EnergyReporting { var kineticEnergy: Double { get } }
```

### Provide Default Implementations

Use protocol extensions for shared behavior:

```swift
extension Collection where Element: Steppable {
    mutating func stepAll(dt: Double) { ... }
}
```

## Error Handling

### Use Typed Throws (Swift 6+)

Prefer typed throws for recoverable, domain-specific errors:

```swift
enum FileSystemError: Error {
    case notFound(String)
    case permissionDenied(String)
}

func read(at path: String) throws(FileSystemError) -> Data { ... }
```

### Reserve Preconditions for Programmer Errors

```swift
// Programmer error — crash immediately
precondition(index >= 0, "Index must be non-negative")

// Runtime error — throw
guard let data = try? Data(contentsOf: url) else {
    throw FileSystemError.notFound(url.path)
}
```

## Concurrency

### Prefer Actors Over Locks

```swift
// Good — compiler-enforced safety
actor Counter {
    private var value = 0
    func increment() { value += 1 }
}

// Avoid — manual synchronization
class Counter {
    private let lock = NSLock()
    private var value = 0
    func increment() { lock.lock(); value += 1; lock.unlock() }
}
```

### Mark Sendable Explicitly

Value types crossing isolation boundaries must be `Sendable`:

```swift
public struct Vec2: Sendable { ... }
public struct Particle: Sendable { ... }
```

## Performance

### Use Value Types for Data

Structs avoid heap allocation and enable compiler optimizations:

```swift
struct Vec2 { var x, y: Double }  // Stack-allocated, no ARC
```

### Copy-on-Write for Large Buffers

Wrap reference storage with `isKnownUniquelyReferenced`:

```swift
struct COWBuffer<T> {
    private var storage: Storage
    mutating func modify(_ transform: (inout [T]) -> Void) {
        if !isKnownUniquelyReferenced(&storage) {
            storage = storage.copy()
        }
        transform(&storage.elements)
    }
}
```

## Documentation

### Document Every Public Symbol

Use triple-slash comments with parameter and return descriptions:

```swift
/// Integrate the ODE state forward by `dt` using fourth-order Runge-Kutta.
///
/// - Parameters:
///   - state: The current state to integrate.
///   - dt: Time step in seconds.
/// - Returns: The new state after integration.
public func rk4<S: ODEState>(state: S, dt: Double) -> S { ... }
```

### Group with MARK Comments

```swift
// MARK: - Public API
// MARK: - Internal Helpers
// MARK: - Protocol Conformances
```
