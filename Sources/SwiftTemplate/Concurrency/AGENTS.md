# AGENTS.md — Concurrency Module

`Concurrency.swift` demonstrates four layers of Swift concurrency, in order:
GCD (`GCDPatterns`), async/await (`AsyncPatterns`), actors (`Counter`, `Cache`),
and structured concurrency (`StructuredConcurrency`). Keep that progression —
new material goes in the section matching its abstraction level.

## Which tool for which job (the module's own teaching point)

- **New async code** → `async/await` + `TaskGroup`. GCD patterns exist here to
  demonstrate legacy interop, not as a recommendation.
- **Shared mutable state** → `actor` (see `Counter`, `Cache`). Do not add
  lock-based classes unless demonstrating the lock itself (`ReadWriteLock`).
- **Bridging callback APIs** → `withCheckedContinuation` /
  `withCheckedThrowingContinuation` (see `AsyncPatterns.bridgedAsyncCall`).
  Resume exactly once on every path.
- **Streams of values** → `AsyncStream` with explicit `continuation.finish()`.

## Established patterns to reuse

- **Order-preserving parallel map**: tag each task with its index, collect
  `(Int, R)` pairs, sort at the end — see `StructuredConcurrency.parallelMap`.
  Never assume TaskGroup completion order.
- **Bounded concurrency**: seed `maxConcurrency` tasks, add one as each
  completes — see `throttledMap`. Don't spawn unbounded task counts.
- **First-wins racing**: `group.next()` then `group.cancelAll()` — see `race`.
- **Preallocated result slots for GCD fan-out**: `parallelBatch` writes each
  index from exactly one task into an `UnsafeMutablePointer`, justified with an
  inline comment:
  ```swift
  // nonisolated(unsafe): each index is written by exactly one task — no data race.
  ```
  Any `nonisolated(unsafe)` you add needs an equivalent proof-of-safety comment.

## Constraints

- All closures crossing threads are `@Sendable`; generic parameters that cross
  tasks are constrained `: Sendable`. StrictConcurrency will reject anything less.
- `ReadWriteLock` is `@unchecked Sendable` because the concurrent queue + barrier
  serializes access. If you touch it, preserve that invariant (reads `sync`,
  writes `async(flags: .barrier)`).
- This file is fully cross-platform: only `Foundation` +
  `#if canImport(FoundationNetworking)`. Keep it that way — no Apple-only APIs.
- Tests (`Tests/SwiftTemplateTests/ConcurrencyTests.swift`) use `async` test
  functions and confirmation-free assertions. Avoid timing-based assertions;
  prefer deterministic completion (await the result, then `#expect`).
- `Task.sleep` belongs in demos of streams/timing only — never as a
  synchronization mechanism in tests or utilities.
