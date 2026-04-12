# Swift Best Practices Guide

Patterns and idioms for writing robust, performant Swift across platforms.

---

## 1. Naming & API Design

Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/):

```swift
// ✅ Methods read as grammatical English phrases
func insert(_ element: Element, at index: Int)
func distance(from start: Index, to end: Index) -> Int

// ❌ Unclear at call site
func insert(_ element: Element, _ index: Int)
func dist(_ s: Index, _ e: Index) -> Int

// ✅ Mutating/non-mutating pairs: verb vs noun/past-participle
array.sort()           // mutating
array.sorted()         // non-mutating returns new value

set.formUnion(other)   // mutating
set.union(other)       // non-mutating

// ✅ Boolean properties read as assertions
var isEmpty: Bool
var canBecomeFirstResponder: Bool

// ❌ Ambiguous
var empty: Bool
var firstResponder: Bool
```

## 2. Protocol-Oriented Programming

Prefer protocols over class inheritance. Use protocol extensions for shared behavior.

```swift
// Define capability, not identity
protocol Renderable {
    func render(into context: inout RenderContext)
}

// Default implementations via extensions
extension Renderable {
    func renderToImage(size: CGSize) -> Image {
        var context = RenderContext(size: size)
        render(into: &context)
        return context.makeImage()
    }
}

// Constrained extensions for specialized behavior
extension Collection where Element: Renderable {
    func renderAll(into context: inout RenderContext) {
        for element in self { element.render(into: &context) }
    }
}

// Protocol composition for flexible requirements
func process(_ item: some Renderable & Sendable) { ... }
```

**Associated types** for generic protocols:

```swift
protocol SimulationState {
    associatedtype Vector: SIMD where Vector.Scalar: FloatingPoint
    var position: Vector { get set }
    var velocity: Vector { get set }
    mutating func step(dt: Vector.Scalar)
}
```

**Use `some` and `any` intentionally:**

```swift
// `some` — opaque type, compiler knows concrete type, zero overhead
func makeRenderer() -> some Renderable { MetalRenderer() }

// `any` — existential box, runtime dispatch, heap allocation
func renderers() -> [any Renderable] { [MetalRenderer(), SoftwareRenderer()] }
```

## 3. Value Types & Copy-on-Write

Prefer structs for data models. Use classes only when identity or reference semantics are needed.

```swift
// ✅ Value type — safe, predictable, stack-allocated when possible
struct Particle {
    var position: SIMD3<Float>
    var velocity: SIMD3<Float>
    var mass: Float
}

// Copy-on-write for large value types with heap storage
struct ParticleSystem {
    private final class Storage {
        var particles: [Particle]
        init(_ particles: [Particle]) { self.particles = particles }
        func copy() -> Storage { Storage(particles) }
    }

    private var storage: Storage

    var particles: [Particle] {
        get { storage.particles }
        set {
            if !isKnownUniquelyReferenced(&storage) {
                storage = storage.copy()
            }
            storage.particles = newValue
        }
    }
}
```

**When to use classes:**
- Shared mutable state (use actors in concurrent code)
- Inheriting from Objective-C classes (UIViewController, NSObject)
- Identity matters (two references should point to the same instance)

## 4. Error Handling

Use Swift's typed error system. Design errors for the caller.

```swift
// Typed errors (Swift 6+)
enum ParseError: Error, LocalizedError {
    case invalidFormat(String)
    case overflow(value: Int, max: Int)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let detail): "Invalid format: \(detail)"
        case .overflow(let v, let m): "Value \(v) exceeds maximum \(m)"
        }
    }
}

// Typed throws — caller knows exact error type, no casting
func parse(_ input: String) throws(ParseError) -> Config {
    guard input.hasPrefix("{") else {
        throw .invalidFormat("expected JSON object")
    }
    // ...
}

// Result for async callbacks or when storing errors
func load(url: URL) async -> Result<Data, NetworkError> { ... }

// rethrows — generic functions that conditionally throw
func retry<T>(times: Int, _ body: () throws -> T) rethrows -> T {
    for attempt in 1...times {
        do { return try body() }
        catch where attempt < times { continue }
    }
    return try body()
}
```

**Error handling patterns:**

```swift
// do-catch with pattern matching
do {
    let config = try parse(input)
} catch .invalidFormat(let detail) {
    log("Bad format: \(detail)")
} catch .overflow(let value, let max) {
    log("Overflow: \(value) > \(max)")
}

// try? for optional conversion (discard error details)
let config = try? parse(input)

// guard with try for early exit
guard let data = try? loadFile(at: path) else { return nil }
```

## 5. Memory Management (ARC)

Swift uses Automatic Reference Counting. Understand the ownership model to avoid leaks.

**Retain cycles — the main hazard:**

```swift
// ❌ Retain cycle: self → closure → self
class Renderer {
    var onFrame: (() -> Void)?
    func start() {
        onFrame = { self.draw() }  // strong capture of self
    }
}

// ✅ Break cycle with [weak self]
class Renderer {
    var onFrame: (() -> Void)?
    func start() {
        onFrame = { [weak self] in self?.draw() }
    }
}

// ✅ Use [unowned self] when you guarantee self outlives the closure
class Renderer {
    lazy var pipeline: Pipeline = {
        Pipeline(device: self.device)  // self always alive when lazy var accessed
    }()
}
```

**Capture list best practices:**

```swift
// Capture specific values, not self, when possible
func animate(particle: Particle) {
    let startPos = particle.position
    Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [startPos] _ in
        // Uses captured value, no reference cycle risk
        interpolate(from: startPos, ...)
    }
}
```

**Autoreleasepool** for tight loops bridging to Objective-C:

```swift
for i in 0..<1_000_000 {
    autoreleasepool {
        let image = processFrame(i)  // Obj-C bridged objects released each iteration
        write(image, to: outputURL)
    }
}
```

## 6. General Idioms

**Use `guard` for preconditions:**

```swift
func process(data: Data?) throws -> Result {
    guard let data, !data.isEmpty else { throw ProcessingError.noData }
    guard data.count <= maxSize else { throw ProcessingError.tooLarge(data.count) }
    // Happy path continues unindented
    return transform(data)
}
```

**Leverage `defer` for cleanup:**

```swift
func withTemporaryFile<T>(_ body: (URL) throws -> T) throws -> T {
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    FileManager.default.createFile(atPath: url.path, contents: nil)
    defer { try? FileManager.default.removeItem(at: url) }
    return try body(url)
}
```

**Property wrappers for cross-cutting concerns:**

```swift
@propertyWrapper
struct Clamped<Value: Comparable> {
    var wrappedValue: Value { didSet { wrappedValue = min(max(wrappedValue, range.lowerBound), range.upperBound) } }
    let range: ClosedRange<Value>
    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.wrappedValue = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}

struct AudioMixer {
    @Clamped(0.0...1.0) var volume: Double = 0.8
    @Clamped(-1.0...1.0) var pan: Double = 0.0
}
```

**Prefer `let` over `var`. Prefer immutability.**

```swift
// ✅ Immutable by default
let config = try loadConfig()
let particles = (0..<count).map { Particle(id: $0) }

// var only when mutation is needed
var accumulator = SIMD4<Float>.zero
for p in particles { accumulator += p.force }
```

---

## Quick Reference

| Principle | Do | Don't |
|---|---|---|
| Types | Structs for data, classes for identity | Classes for everything |
| Protocols | Composition + extensions | Deep inheritance hierarchies |
| Errors | Typed throws, descriptive cases | Stringly-typed errors |
| Memory | `[weak self]` in escaping closures | Assume ARC handles everything |
| Optionals | `guard let` early return | Nested `if let` pyramids |
| Concurrency | Actors for shared state | Manual locks (usually) |
| Naming | Clarity at the call site | Abbreviations |

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TUTORIAL.md](TUTORIAL.md) · [EXTENDING.md](EXTENDING.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
