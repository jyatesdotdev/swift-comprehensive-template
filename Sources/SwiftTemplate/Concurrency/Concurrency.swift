// MARK: - Concurrency Module
// GCD, async/await, actors, structured concurrency, TaskGroups

import Foundation

// MARK: - 1. Grand Central Dispatch (GCD)

/// Demonstrates GCD patterns: serial/concurrent queues, groups, barriers.
public enum GCDPatterns {

    /// Serial queue for ordered, thread-safe access to a resource.
    public static let serialQueue = DispatchQueue(label: "com.template.serial")

    /// Concurrent queue for parallel work.
    public static let concurrentQueue = DispatchQueue(
        label: "com.template.concurrent",
        attributes: .concurrent
    )

    /// Fan-out work with DispatchGroup, calling completion when all finish.
    ///
    /// - Parameters:
    ///   - items: The integers to transform in parallel.
    ///   - transform: A sendable closure applied to each item.
    ///   - completion: Called on the main queue with the ordered results.
    public static func parallelBatch(
        items: [Int],
        transform: @Sendable @escaping (Int) -> Int,
        completion: @Sendable @escaping ([Int]) -> Void
    ) {
        let group = DispatchGroup()
        let count = items.count
        // nonisolated(unsafe): each index is written by exactly one task — no data race.
        nonisolated(unsafe) let base = UnsafeMutablePointer<Int>.allocate(capacity: count)
        base.initialize(repeating: 0, count: count)

        for (i, item) in items.enumerated() {
            group.enter()
            concurrentQueue.async {
                base.advanced(by: i).pointee = transform(item)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let results = Array(UnsafeBufferPointer(start: base, count: count))
            base.deallocate()
            completion(results)
        }
    }

    /// Reader-writer pattern using a concurrent queue with barrier writes.
    public final class ReadWriteLock<Value: Sendable>: @unchecked Sendable {
        private var _value: Value
        private let queue = DispatchQueue(label: "com.template.rwlock", attributes: .concurrent)

        /// Creates a lock protecting the given initial value.
        ///
        /// - Parameter value: The initial protected value.
        public init(_ value: Value) { _value = value }

        /// Reads the current value synchronously.
        ///
        /// - Returns: The current protected value.
        public func read() -> Value {
            queue.sync { _value }
        }

        /// Writes to the protected value using a barrier.
        ///
        /// - Parameter transform: A closure that mutates the value in-place.
        public func write(_ transform: @Sendable @escaping (inout Value) -> Void) {
            queue.async(flags: .barrier) { transform(&self._value) }
        }
    }
}

// MARK: - 2. Async/Await

/// Demonstrates modern async/await patterns.
public enum AsyncPatterns {

    /// Fetches data from a URL, throwing on non-2xx status codes.
    ///
    /// - Parameter url: The URL to fetch.
    /// - Returns: The response body as `Data`.
    /// - Throws: `URLError(.badServerResponse)` on non-2xx status.
    public static func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    /// Bridge callback-based API to async/await using a continuation.
    ///
    /// - Returns: The bridged result (always `42` in this demo).
    public static func bridgedAsyncCall() async -> Int {
        await withCheckedContinuation { continuation in
            GCDPatterns.serialQueue.async {
                continuation.resume(returning: 42)
            }
        }
    }

    /// Creates an async sequence that counts down from `n` to 0.
    ///
    /// - Parameter n: The starting value for the countdown.
    /// - Returns: An `AsyncStream` yielding integers from `n` down to `0`.
    public static func countdown(from n: Int) -> AsyncStream<Int> {
        AsyncStream { continuation in
            Task {
                for i in stride(from: n, through: 0, by: -1) {
                    continuation.yield(i)
                    try? await Task.sleep(for: .milliseconds(100))
                }
                continuation.finish()
            }
        }
    }
}

// MARK: - 3. Actors

/// Thread-safe counter using actor isolation.
public actor Counter {
    private var value: Int

    /// Creates a counter with the given initial value.
    ///
    /// - Parameter initial: The starting count. Defaults to `0`.
    public init(_ initial: Int = 0) { value = initial }

    /// Returns the current count.
    ///
    /// - Returns: The current value.
    public func get() -> Int { value }

    /// Increments the counter and returns the new value.
    ///
    /// - Parameter delta: The amount to add. Defaults to `1`.
    /// - Returns: The updated count.
    public func increment(by delta: Int = 1) -> Int {
        value += delta
        return value
    }

    /// Resets the counter to zero.
    public func reset() { value = 0 }
}

/// Cache actor demonstrating nonisolated and isolated access patterns.
public actor Cache<Key: Hashable & Sendable, Value: Sendable> {
    private var storage: [Key: Value] = [:]

    /// Creates an empty cache.
    public init() {}

    /// Returns the cached value for `key`, or `nil` if absent.
    ///
    /// - Parameter key: The cache key.
    /// - Returns: The cached value, or `nil`.
    public func get(_ key: Key) -> Value? { storage[key] }

    /// Stores a value in the cache.
    ///
    /// - Parameters:
    ///   - key: The cache key.
    ///   - value: The value to store.
    public func set(_ key: Key, value: Value) { storage[key] = value }

    /// Returns the cached value for `key`, computing and caching it if absent.
    ///
    /// - Parameters:
    ///   - key: The cache key.
    ///   - provider: An async closure that produces the default value.
    /// - Returns: The existing or newly computed value.
    public func getOrSet(_ key: Key, default provider: @Sendable () async -> Value) async -> Value {
        if let existing = storage[key] { return existing }
        let value = await provider()
        storage[key] = value
        return value
    }

    /// nonisolated property — no actor hop needed.
    nonisolated public var description: String { "Cache<\(Key.self), \(Value.self)>" }
}

// MARK: - 4. Structured Concurrency & TaskGroups

/// Demonstrates TaskGroup, parallel map, and cancellation.
public enum StructuredConcurrency {

    /// Transforms each element in parallel, preserving order.
    ///
    /// - Parameters:
    ///   - items: The input collection.
    ///   - transform: An async throwing closure applied to each element.
    /// - Returns: An array of transformed results in the original order.
    public static func parallelMap<T: Sendable, R: Sendable>(
        _ items: [T],
        transform: @Sendable @escaping (T) async throws -> R
    ) async rethrows -> [R] {
        try await withThrowingTaskGroup(of: (Int, R).self) { group in
            for (i, item) in items.enumerated() {
                group.addTask { (i, try await transform(item)) }
            }
            var results = [(Int, R)]()
            results.reserveCapacity(items.count)
            for try await pair in group { results.append(pair) }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    /// Runs multiple tasks concurrently and returns the first successful result.
    ///
    /// - Parameter tasks: An array of async throwing closures to race.
    /// - Returns: The result of the first task to complete successfully.
    /// - Throws: `CancellationError` if no tasks are provided, or rethrows task errors.
    public static func race<R: Sendable>(
        _ tasks: [@Sendable () async throws -> R]
    ) async throws -> R {
        try await withThrowingTaskGroup(of: R.self) { group in
            for task in tasks {
                group.addTask { try await task() }
            }
            guard let first = try await group.next() else {
                throw CancellationError()
            }
            group.cancelAll()
            return first
        }
    }

    /// Transforms elements with bounded concurrency.
    ///
    /// - Parameters:
    ///   - items: The input collection.
    ///   - maxConcurrency: Maximum number of in-flight tasks.
    ///   - transform: An async throwing closure applied to each element.
    /// - Returns: An array of transformed results in the original order.
    public static func throttledMap<T: Sendable, R: Sendable>(
        _ items: [T],
        maxConcurrency: Int,
        transform: @Sendable @escaping (T) async throws -> R
    ) async rethrows -> [R] {
        try await withThrowingTaskGroup(of: (Int, R).self) { group in
            var results = [(Int, R)]()
            results.reserveCapacity(items.count)
            var index = 0

            // Seed initial batch
            for _ in 0..<min(maxConcurrency, items.count) {
                let i = index
                group.addTask { (i, try await transform(items[i])) }
                index += 1
            }

            // As each completes, add next
            for try await pair in group {
                results.append(pair)
                if index < items.count {
                    let i = index
                    group.addTask { (i, try await transform(items[i])) }
                    index += 1
                }
            }

            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }
}
