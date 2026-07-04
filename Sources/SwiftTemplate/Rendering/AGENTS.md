# AGENTS.md — Rendering Module

`Rendering.swift` has five sections in three availability tiers:

| Tier | Sections | Guard |
|---|---|---|
| GPU (Apple) | `MetalRendering` | `#if canImport(Metal)` |
| 2D (Apple) | `CoreGraphicsRendering`, SwiftUI `RegularPolygon`/`Star` | `#if canImport(CoreGraphics)` / `canImport(SwiftUI)` |
| Portable | `Color4`, `PixelBuffer`, `GameScene`, `GameLoop` | none — must build on Linux |

New rendering code goes in the **lowest tier that can express it**. If it can be
done with the software `PixelBuffer`, do it there so Linux gets it too.

## Established patterns to reuse

- **Failable init for hardware**: `GPUContext.init?()` returns `nil` when no
  Metal device exists — callers decide how to degrade. Never `fatalError` on
  missing hardware.
- **Metal resource creation returns optionals**; the existing code converts
  failures to thrown `MetalError` cases (`functionNotFound`, 
  `resourceCreationFailed`). Extend that enum rather than throwing strings.
- **Thread dispatch**: compute grid sizes from `pipeline.threadExecutionWidth`,
  clamp threadgroup size to the element count — see `doubleArray`.
- **SwiftUI shapes** clamp their inputs in `init` (`max(3, sides)`) instead of
  trapping, and carry `@available(macOS 14.0, iOS 17.0, *)`.
- **PixelBuffer** does bounds-clamping in `fillRect` / bounds-checking in
  `drawLine`; its subscript is unchecked for speed. Keep public drawing APIs
  clamp-safe.
- **GameLoop** is the fixed-timestep accumulator pattern: `update(dt:)` runs
  zero or more times per frame at a constant `tickRate`, `render` once. `scene`
  is `weak` to avoid retain cycles. It is `@unchecked Sendable` — external
  callers drive it from one thread.

## Constraints & pitfalls

- Never let a Metal/CoreGraphics/SwiftUI symbol leak outside its `#if` block —
  the Linux build (and CI cross-platform expectations) will break.
- GPU tests must handle machines without Metal: construct `GPUContext()` and
  skip (early-return) when it is `nil`. CI runners may not have a GPU.
- Inline MSL shader source in Swift strings is the accepted pattern here for
  self-contained demos; keep shaders tiny and colocated with their host function.
- Rendering output is deterministic (no time, no randomness) so tests can
  assert exact pixels — see `RenderingTests.swift`. Preserve determinism.
