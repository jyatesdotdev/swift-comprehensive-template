# Concurrency Guide

Swift's concurrency model spans legacy GCD through modern structured concurrency. This module demonstrates practical patterns for each layer.

## 1. Grand Central Dispatch (GCD)

GCD remains relevant for low-level queue management and bridging to async/await.

### Serial Queues
Use for ordered, thread-safe mutation of shared state:
```swift
GCDPatterns.serialQueue.async { sharedState.append(item) }
```

### Concurrent Queues + Barriers
`ReadWriteLock` demonstrates the reader-writer pattern — concurrent reads, exclusive writes:
```swift
let cache = GCDPatterns.ReadWriteLock(["key": "value"])
let val = cache.read()          // concurrent
cache.write { $0["key"] = "new" } // exclusive barrier
```

### DispatchGroup
`parallelBatch` fans out work and joins on completion:
```swift
GCDPatterns.parallelBatch(items: [1,2,3], transform: { $0 * 2 }) { results in
    print(results) // [2, 4, 6]
}
```

## 2. Async/Await

### Basic Usage
```swift
let data = try await AsyncPatterns.fetchData(from: url)
```

### Bridging Callbacks
Use `withCheckedContinuation` to wrap callback APIs:
```swift
let value = await AsyncPatterns.bridgedAsyncCall()
```

### AsyncStream
Produce values over time:
```swift
for await n in AsyncPatterns.countdown(from: 5) {
    print(n) // 5, 4, 3, 2, 1, 0
}
```

## 3. Actors

Actors provide compile-time data race safety. All mutable state is isolated.

```swift
let counter = Counter(0)
let val = await counter.increment(by: 5) // 5
```

### Cache Actor
Demonstrates `nonisolated` properties and async default providers:
```swift
let cache = Cache<String, Data>()
let data = await cache.getOrSet("key") { await fetchExpensiveData() }
```

## 4. Structured Concurrency

### Parallel Map
Order-preserving parallel transform:
```swift
let results = await StructuredConcurrency.parallelMap([1,2,3]) { $0 * 2 }
// [2, 4, 6]
```

### Race
Returns the first successful result, cancels the rest:
```swift
let fastest = try await StructuredConcurrency.race([
    { try await fetchFromCDN() },
    { try await fetchFromOrigin() }
])
```

### Throttled Concurrency
Limit in-flight tasks to avoid overwhelming resources:
```swift
let results = try await StructuredConcurrency.throttledMap(
    urls, maxConcurrency: 4
) { url in try await fetch(url) }
```

## When to Use What

| Pattern | Use Case |
|---------|----------|
| GCD serial queue | Legacy code, simple mutual exclusion |
| GCD concurrent + barrier | Reader-writer locks |
| async/await | Any new async code |
| Continuations | Bridging callback APIs |
| Actors | Shared mutable state |
| TaskGroup | Fan-out/fan-in parallelism |
| Throttled map | Rate-limited parallel work |

## Strict Concurrency Notes

This project enables `StrictConcurrency`. Key rules:
- Values crossing isolation boundaries must be `Sendable`
- Use `@Sendable` on closures passed to other isolation domains
- Mark classes as `@unchecked Sendable` only when you manually guarantee safety (e.g., `ReadWriteLock`)
- Actors are implicitly `Sendable`

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TUTORIAL.md](TUTORIAL.md) · [BestPractices.md](BestPractices.md) · [TOOLCHAIN.md](TOOLCHAIN.md)
