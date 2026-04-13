#if canImport(Testing)
import Testing
import Foundation
@testable import SwiftTemplate

// MARK: - Async Concurrency Tests

@Suite("Concurrency")
struct ConcurrencyTests {

    @Test func counterActor() async {
        let counter = Counter(0)
        let val = await counter.increment(by: 5)
        #expect(val == 5)
        #expect(await counter.get() == 5)
        await counter.reset()
        #expect(await counter.get() == 0)
    }

    @Test func cacheActor() async {
        let cache = Cache<String, Int>()
        await cache.set("a", value: 1)
        #expect(await cache.get("a") == 1)
        #expect(await cache.get("b") == nil)
    }

    @Test func cacheGetOrSet() async {
        let cache = Cache<String, Int>()
        let val = await cache.getOrSet("x") { 42 }
        #expect(val == 42)
        let val2 = await cache.getOrSet("x") { 99 }
        #expect(val2 == 42, "Should return cached value")
    }

    @Test func parallelMap() async throws {
        let input = Array(1...10)
        let result = try await StructuredConcurrency.parallelMap(input) { $0 * $0 }
        #expect(result == input.map { $0 * $0 })
    }

    @Test func throttledMap() async throws {
        let input = Array(1...20)
        let result = try await StructuredConcurrency.throttledMap(input, maxConcurrency: 4) { $0 + 1 }
        #expect(result == input.map { $0 + 1 })
    }
}

// MARK: - Additional Concurrency Tests

@Suite("ConcurrencyExtended")
struct ConcurrencyExtendedTests {

    @Test func readWriteLock() async {
        let lock = GCDPatterns.ReadWriteLock(0)
        #expect(lock.read() == 0)
        lock.write { $0 = 42 }
        try? await Task.sleep(for: .milliseconds(50))
        #expect(lock.read() == 42)
    }

    @Test func parallelBatch() async {
        let items = [1, 2, 3, 4]
        let result = await withCheckedContinuation { (cont: CheckedContinuation<[Int], Never>) in
            GCDPatterns.parallelBatch(items: items, transform: { $0 * 2 }, completion: { results in
                cont.resume(returning: results)
            })
        }
        #expect(result == [2, 4, 6, 8])
    }

    @Test func bridgedAsyncCall() async {
        let val = await AsyncPatterns.bridgedAsyncCall()
        #expect(val == 42)
    }

    @Test func countdown() async {
        var values: [Int] = []
        for await v in AsyncPatterns.countdown(from: 3) {
            values.append(v)
        }
        #expect(values == [3, 2, 1, 0])
    }

    @Test func race() async throws {
        let result = try await StructuredConcurrency.race([
            { 1 },
            { 2 }
        ])
        #expect(result == 1 || result == 2)
    }

    @Test func cacheDescription() {
        let cache = Cache<String, Int>()
        #expect(cache.description == "Cache<String, Int>")
    }
}

// MARK: - Performance Testing Patterns

@Suite("Performance")
struct PerformancePatternTests {

    @Test func vec2ArithmeticThroughput() {
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            var v = Vec2(1, 1)
            for _ in 0..<100_000 { v += Vec2(0.001, 0.001) }
            _ = v
        }
        #expect(elapsed < .seconds(1))
    }

    @Test func batchDotThroughput() {
        let n = 10_000
        let a = [Float](repeating: 1.0, count: n)
        let b = [Float](repeating: 2.0, count: n)
        let clock = ContinuousClock()
        let elapsed = clock.measure { _ = SIMDOps.batchDot(a, b) }
        #expect(elapsed < .seconds(1))
    }
}

#elseif canImport(XCTest)
import XCTest
@testable import SwiftTemplate

final class ConcurrencyXCTests: XCTestCase {
    func testCounter() async {
        let c = Counter(0); let v = await c.increment(by: 5); XCTAssertEqual(v, 5)
    }
    func testParallelMap() async throws {
        let r = try await StructuredConcurrency.parallelMap([1, 2, 3]) { $0 * $0 }
        XCTAssertEqual(r, [1, 4, 9])
    }
}

final class PerformanceXCTests: XCTestCase {
    func testVec2Performance() {
        measure {
            var v = Vec2(1, 1); for _ in 0..<100_000 { v += Vec2(0.001, 0.001) }; _ = v
        }
    }
    func testBatchDotPerformance() {
        let a = [Float](repeating: 1, count: 10_000), b = [Float](repeating: 2, count: 10_000)
        measure { _ = SIMDOps.batchDot(a, b) }
    }
}
#endif
