# High-Performance Computing Guide

## Overview

Swift provides strong HPC capabilities through built-in SIMD types, the Accelerate framework, and GCD-based parallelism. This module demonstrates patterns for numerical computing, vectorized operations, and performance optimization.

## 1. SIMD Operations

Swift has first-class SIMD support (`SIMD2`, `SIMD4`, `SIMD8`, etc.) that maps directly to hardware vector instructions.

```swift
// Fused multiply-add on 4 floats at once
let result = SIMDOps.multiplyAdd(
    SIMD4(1, 2, 3, 4),
    SIMD4(2, 2, 2, 2),
    SIMD4(10, 10, 10, 10)
) // [12, 14, 16, 18]

// Batch dot product using SIMD4 chunks
let dot = SIMDOps.batchDot(arrayA, arrayB)
```

Key points:
- Use `&*` and `&+` for wrapping arithmetic (avoids overflow checks)
- Mark hot functions `@inlinable` to enable cross-module optimization
- Process arrays in SIMD-width chunks with a scalar remainder loop

## 2. Accelerate Framework (Apple platforms)

### vDSP — Signal Processing
```swift
let sum = AccelerateOps.vectorAdd(a, b)
let (real, imag) = AccelerateOps.fft(signal)
let level = AccelerateOps.rms(signal)
```

### BLAS — Linear Algebra
```swift
// Matrix multiply: C = A × B
let c = AccelerateOps.matmul(a: matA, b: matB, m: 4, n: 4, k: 4)
```

Accelerate uses hand-tuned SIMD and multi-core implementations under the hood. Always prefer it over manual loops for large data.

## 3. Parallel Processing

### concurrentPerform (GCD)
```swift
// Parallel map — uses all cores, no async overhead
let results = ParallelProcessing.concurrentMap(items) { item in
    expensiveTransform(item)
}
```

### Parallel Reduce
```swift
let total = ParallelProcessing.concurrentReduce(
    numbers, initial: 0, chunkSize: 1024
) { $0 + $1 }
```

`concurrentPerform` is ideal for CPU-bound work with no I/O. It blocks the calling thread until all iterations complete, making it simpler than TaskGroup for pure computation.

## 4. Memory Optimization

### Aligned Buffers
```swift
let buf = MemoryOptimization.AlignedBuffer<Float>(count: 1024, alignment: 64)
for i in 0..<1024 { buf[i] = Float(i) }
```

Page-aligned allocations improve cache behavior and are required by some GPU/SIMD operations.

### Measuring Performance
```swift
MemoryOptimization.measure("matmul") {
    AccelerateOps.matmul(a: a, b: b, m: 512, n: 512, k: 512)
}
// [matmul] 1.234 ms
```

## Optimization Checklist

- Prefer `Array` with `reserveCapacity` to avoid reallocations
- Use `@inlinable` on hot-path functions for cross-module inlining
- Use `withUnsafeBufferPointer` to avoid bounds checks in tight loops
- Prefer Accelerate over hand-written loops for vector/matrix math
- Use `concurrentPerform` for CPU-bound parallel work
- Profile with Instruments (Time Profiler, Allocations) before optimizing

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TUTORIAL.md](TUTORIAL.md) · [BestPractices.md](BestPractices.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
