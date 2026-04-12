# Simulation Guide

## Overview

The Simulation module covers numerical computing, physics simulation, and Core Animation patterns — demonstrating Swift's suitability for scientific and interactive applications.

## 1. Numerical Computing

### Vec2
Lightweight 2D vector with arithmetic operators, normalization, and length. Conforms to `ODEState` for use with integrators.

### Integrators
- **Euler** — First-order, simple but accumulates error quickly
- **RK4** — Fourth-order Runge-Kutta, much more accurate for the same step size
- **Trapezoidal rule** — Numerical definite integration

```swift
// Solve dy/dt = -2y from y(0) = 1
var y = 1.0
for _ in 0..<100 {
    y = Integrator.rk4(state: y, t: 0, dt: 0.01) { _, y in -2 * y }
}
// y ≈ e^(-2) ≈ 0.1353
```

### Generic ODEState Protocol
Any type conforming to `ODEState` (requires `+` and `*` by scalar) works with both integrators — `Double`, `Vec2`, or custom state vectors.

## 2. Physics Simulation

### Particle & Verlet Integration
Particles use Störmer-Verlet integration — position-based, stable, and simple. No explicit velocity storage; velocity is implicit from position history.

### ParticleSystem
Manages a collection of particles with gravity and ground-plane collision. Call `step(dt:)` each frame.

### Springs
Position-based constraint relaxation between particle pairs. Apply after integration to maintain distance constraints (cloth, soft bodies).

### AABB Collision
Axis-aligned bounding box overlap test for broad-phase collision detection.

```swift
var system = ParticleSystem()
system.addParticle(Particle(position: Vec2(0, 10), mass: 1.0))
for _ in 0..<600 {
    system.step(dt: 1.0 / 60.0)
}
// Particle bounces on ground at y=0
```

## 3. Core Animation (macOS/iOS)

Guarded with `#if canImport(QuartzCore)`. Patterns include:
- **Position animation** — CABasicAnimation with ease-in-ease-out
- **Path animation** — CAKeyframeAnimation along a CGPath
- **Spring animation** — CASpringAnimation with configurable damping/stiffness/mass
- **Custom timing** — Cubic Bézier CAMediaTimingFunction

These are factory methods returning configured animation objects ready to add to a CALayer.

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TUTORIAL.md](TUTORIAL.md) · [HPCGuide.md](HPCGuide.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
