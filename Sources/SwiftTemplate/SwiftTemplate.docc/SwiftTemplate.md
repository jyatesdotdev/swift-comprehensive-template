# ``SwiftTemplate``

A comprehensive Swift template for systems programming, high-performance computing, rendering, concurrency, and simulation.

## Overview

SwiftTemplate demonstrates Swift's capabilities beyond iOS development. It provides production-ready patterns for:

- **Concurrency** — GCD, async/await, actors, structured concurrency
- **Rendering** — Metal compute, Core Graphics, SwiftUI shapes, game loops
- **Systems Programming** — File I/O, process management, signals, unsafe memory
- **High-Performance Computing** — SIMD, Accelerate, parallel processing
- **Simulation** — ODE integrators, particle systems, physics, Core Animation

All code compiles cross-platform where possible, with Apple-specific APIs guarded behind `#if canImport()`.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:APIDesignGuidelines>

### Concurrency

- ``GCDPatterns``
- ``Counter``
- ``Cache``

### Rendering

- ``PixelBuffer``

### Systems Programming

- ``FileSystem``
- ``Shell``

### High-Performance Computing

- ``SIMDOps``
- ``ParallelProcessing``

### Simulation

- ``Vec2``
- ``Particle``
- ``ParticleSystem``

### Best Practices

- ``Steppable``
- ``COWBuffer``
- ``Clamped``

### Cross-Platform

- ``Platform``
- ``PortablePath``
