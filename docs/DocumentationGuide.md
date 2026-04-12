# Documentation Guide

How to write, build, and publish documentation for SwiftTemplate using DocC.

## DocC Structure

The documentation catalog lives at `Sources/SwiftTemplate/SwiftTemplate.docc/`:

```
SwiftTemplate.docc/
├── SwiftTemplate.md          # Module landing page (root)
├── GettingStarted.md         # Getting started tutorial
└── APIDesignGuidelines.md    # API design conventions
```

The root file (`SwiftTemplate.md`) uses the `# ``SwiftTemplate`` ` header to link it to the module. Articles use plain `#` headers.

## Building Documentation

### Local Preview

```bash
# Generate and preview in browser (opens http://localhost:8080)
swift package --disable-sandbox preview-documentation --target SwiftTemplate
```

### Generate Archive

```bash
# Produces a .doccarchive bundle
swift package generate-documentation --target SwiftTemplate

# With a custom output path
swift package generate-documentation --target SwiftTemplate --output-path ./docs-out
```

### Xcode

In Xcode: Product → Build Documentation (⌃⇧⌘D).

## Writing Documentation

### Symbol Documentation

Every public symbol should have a doc comment:

```swift
/// A 2D vector for simulation math.
///
/// `Vec2` is a value type optimized for stack allocation.
/// It conforms to `Sendable` for safe use across concurrency domains.
///
/// ```swift
/// let v = Vec2(x: 3, y: 4)
/// print(v.magnitude) // 5.0
/// ```
public struct Vec2: Sendable { ... }
```

### Parameters and Returns

```swift
/// Step the particle forward using Störmer-Verlet integration.
///
/// - Parameters:
///   - dt: Time step in seconds.
///   - acceleration: External acceleration (e.g., gravity).
public mutating func verletStep(dt: Double, acceleration: Vec2) { ... }
```

### Articles

Create `.md` files in the `.docc` directory. Reference them from the root page:

```markdown
## Topics

### Essentials
- <doc:GettingStarted>
- <doc:APIDesignGuidelines>
```

### Linking to Symbols

Use double-backtick syntax to link to types and methods:

```markdown
See ``Vec2`` for the vector type used in ``ParticleSystem``.
```

## Hosting

### GitHub Pages

```bash
# Convert .doccarchive to static site
swift package generate-documentation --target SwiftTemplate \
    --transform-for-static-hosting \
    --hosting-base-path SwiftTemplate \
    --output-path ./docs-out
```

Deploy the `docs-out/` directory to GitHub Pages.

### Swift Package Index

Add a `.spi.yml` at the repo root:

```yaml
version: 1
builder:
  configs:
    - documentation_targets: [SwiftTemplate]
```

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TUTORIAL.md](TUTORIAL.md) · [BestPractices.md](BestPractices.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
