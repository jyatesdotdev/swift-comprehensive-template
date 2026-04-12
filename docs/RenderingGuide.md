# Rendering Pipelines Guide

## Overview

Swift offers multiple rendering approaches depending on platform and use case:

| Layer | Framework | Use Case |
|-------|-----------|----------|
| GPU Compute/Graphics | Metal | Custom shaders, GPGPU, game rendering |
| 2D Drawing | Core Graphics | Bitmap generation, PDF, image processing |
| Declarative UI | SwiftUI | App interfaces, custom shapes, animations |
| Cross-platform | PixelBuffer (custom) | Software rendering, Linux support |

## 1. Metal — GPU Programming

### Device & Command Queue

```swift
let context = MetalRendering.GPUContext()  // wraps MTLDevice + MTLCommandQueue
```

Metal follows a command-buffer architecture:
1. Create a **device** (GPU handle)
2. Create a **command queue** (serializes work)
3. Create a **command buffer** per frame/dispatch
4. Encode commands via **encoders** (compute, render, blit)
5. Commit and optionally wait

### Compute Pipelines

Compile MSL source at runtime and dispatch a kernel:

```swift
let result = try MetalRendering.doubleArray([1, 2, 3, 4], context: ctx)
// result == [2, 4, 6, 8]
```

Key concepts:
- `MTLComputePipelineState` — compiled kernel
- `MTLBuffer` — GPU-accessible memory (`.storageModeShared` for CPU+GPU)
- Thread dispatch: `threadsPerGrid` / `threadsPerThreadgroup`

### Best Practices
- Prefer `.storageModePrivate` for GPU-only data
- Triple-buffer resources to avoid CPU/GPU stalls
- Use `MTLEvent` for cross-queue synchronization
- Profile with Metal System Trace in Instruments

## 2. Core Graphics — 2D Drawing

### Bitmap Contexts

```swift
let ctx = CoreGraphicsRendering.makeContext(width: 512, height: 512)
```

Core Graphics uses a painter's model — draw back-to-front.

### Drawing Primitives

```swift
// Rounded rectangle
let image = CoreGraphicsRendering.drawRoundedRect(
    width: 200, height: 100, cornerRadius: 16,
    fillColor: CGColor(red: 0.2, green: 0.5, blue: 1, alpha: 1)
)

// Linear gradient
let gradient = CoreGraphicsRendering.drawGradient(
    width: 256, height: 256,
    from: CGColor(red: 1, green: 0, blue: 0, alpha: 1),
    to: CGColor(red: 0, green: 0, blue: 1, alpha: 1)
)

// Checkerboard pattern
let checker = CoreGraphicsRendering.drawCheckerboard(
    width: 256, height: 256, tileSize: 32,
    color1: .white, color2: .black
)
```

### Best Practices
- Reuse `CGContext` when drawing multiple frames
- Use `CGLayer` for repeated drawing operations
- Prefer `CGPath` over manual `moveTo`/`lineTo` sequences

## 3. SwiftUI Shapes

### Custom Shape Protocol

Implement `func path(in rect: CGRect) -> Path`:

```swift
RegularPolygon(sides: 6)
    .fill(.blue)
    .frame(width: 100, height: 100)

Star(points: 5, innerRatio: 0.4)
    .stroke(.yellow, lineWidth: 2)
    .frame(width: 100, height: 100)
```

### Animatable Shapes
Conform to `Animatable` and expose `animatableData` to animate shape parameters.

## 4. Cross-Platform Software Rendering

`PixelBuffer` works on all platforms including Linux:

```swift
var buf = PixelBuffer(width: 320, height: 240)
buf.fillRect(x: 10, y: 10, w: 50, h: 50, color: Color4(r: 1, g: 0, b: 0))
buf.drawLine(from: (0, 0), to: (319, 239), color: .white)
```

## 5. Game Loop Pattern

Fixed-timestep loop decouples simulation from rendering:

```swift
let loop = GameLoop(tickRate: 1.0/60.0, scene: myScene)
// In display link callback:
loop.step(elapsed: frameDelta, buffer: &pixelBuffer)
```

This ensures deterministic physics regardless of frame rate.

## Conditional Compilation

All Apple-specific code is guarded:

```swift
#if canImport(Metal)
// Metal code
#endif

#if canImport(CoreGraphics)
// Core Graphics code
#endif

#if canImport(SwiftUI)
// SwiftUI code
#endif
```

The `PixelBuffer`, `Color4`, `GameScene`, and `GameLoop` types are always available.

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TUTORIAL.md](TUTORIAL.md) · [CrossPlatformGuide.md](CrossPlatformGuide.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
