# AGENTS.md — HPC Module

`HPC.swift` covers vectorized and parallel computation in four sections:
`SIMDOps` (portable SIMD), `AccelerateOps` (Apple-only vDSP/BLAS),
`ParallelProcessing` (GCD `concurrentPerform`), and `MemoryOptimization`
(aligned buffers, timing).

## Platform split — the most important rule here

- `SIMDOps` uses Swift's built-in `SIMD4/SIMD8/SIMD3` types, which work on
  **all platforms including Linux**. Portable numeric code goes here.
- `AccelerateOps` is wrapped entirely in `#if canImport(Accelerate)`. Anything
  touching vDSP, BLAS, or LAPACK goes **inside** that block, and every
  Accelerate API needs a portable SIMD or scalar counterpart available so Linux
  users aren't stranded.
- Prefer the `vDSP` struct API (e.g. `vDSP.add`) over raw `vDSP_*` C calls when
  both exist. Matrix multiply uses `vDSP_mmul`, not deprecated `cblas_sgemm`.

## Established patterns to reuse

- **Chunk + tail loop** for arrays that aren't multiples of the SIMD width —
  see `batchDot`: process `count / 4` SIMD chunks, then a scalar tail loop.
- **`precondition(a.count == b.count)`** for length invariants — programmer
  error, not a recoverable throw.
- **`@inlinable`** on small hot-path functions (`multiplyAdd`, `dot`,
  `normalize`) so they inline across module boundaries. Don't add it to large
  functions or anything referencing internal state.
- **Near-zero guards** use `.ulpOfOne`, never `== 0` (see `normalize`).
- **Manual allocation is paired**: every `allocate` has a `deallocate` on all
  paths (via `defer` or immediately after the copy-out). `AlignedBuffer` owns
  its pointer and frees in `deinit`; it is `@unchecked Sendable` — callers are
  responsible for synchronization, keep that documented.
- **`concurrentPerform` result buffers**: `nonisolated(unsafe)` buffer where
  each iteration writes only its own index — same justification-comment rule as
  the Concurrency module. `concurrentReduce` requires an **associative**
  `combine` and documents it; preserve such requirements in doc comments.

## Testing

Tests live in `Tests/SwiftTemplateTests/HPCTests.swift`. Float comparisons use
explicit tolerances (`abs(x - 1.0) < 1e-12`), never `==` on computed floats
(exact `==` is fine for values that are exact by construction, e.g. small
integers in SIMD lanes). Accelerate-dependent tests must sit inside
`#if canImport(Accelerate)`.
