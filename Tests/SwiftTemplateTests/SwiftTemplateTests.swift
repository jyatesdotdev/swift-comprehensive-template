// Comprehensive Testing Setup for SwiftTemplate
// Demonstrates: unit tests, async tests, performance testing patterns
// Uses Swift Testing (#if canImport(Testing)) with XCTest fallback.

#if canImport(Testing)
import Testing
@testable import SwiftTemplate

// MARK: - Best Practices Tests

@Suite("BestPractices")
struct BestPracticesTests {

    @Test func point2DEquality() {
        #expect(Point2D(x: 1, y: 2) == Point2D(x: 1, y: 2))
        #expect(Point2D(x: 1, y: 2) != Point2D(x: 3, y: 4))
        #expect(Point2D() == Point2D(x: 0, y: 0))
    }

    @Test func cowBufferAppendAndCopy() {
        var a = COWBuffer([1, 2, 3])
        var b = a
        b[0] = 99
        #expect(a[0] == 1, "Original unchanged after COW copy")
        #expect(b[0] == 99)
        #expect(a.count == 3)
    }

    @Test func configRequire() throws {
        let config = Config(["host": "localhost", "port": "8080"])
        #expect(try config.require("host") == "localhost")
        #expect(try config.requireInt("port") == 8080)
    }

    @Test func configMissingKey() {
        let config = Config([:])
        #expect(throws: ConfigError.self) { try config.require("missing") }
    }

    @Test func configTypeMismatch() {
        let config = Config(["port": "abc"])
        #expect(throws: ConfigError.self) { try config.requireInt("port") }
    }

    @Test func clampedPropertyWrapper() {
        var settings = AudioSettings()
        #expect(settings.volume == 0.8)
        settings.volume = 1.5
        #expect(settings.volume == 1.0, "Clamps to upper bound")
        settings.volume = -0.5
        #expect(settings.volume == 0.0, "Clamps to lower bound")
        settings.pan = 0.5
        #expect(settings.pan == 0.5)
    }
}

// MARK: - Simulation Tests

@Suite("Simulation")
struct SimulationTests {

    @Test func vec2Arithmetic() {
        let a = Vec2(3, 4), b = Vec2(1, 2)
        #expect(a + b == Vec2(4, 6))
        #expect(a - b == Vec2(2, 2))
        #expect(a * 2.0 == Vec2(6, 8))
        #expect(2.0 * a == Vec2(6, 8))
    }

    @Test func vec2Length() {
        let v = Vec2(3, 4)
        #expect(abs(v.length - 5.0) < 1e-12)
        #expect(Vec2.zero.length == 0.0)
    }

    @Test func vec2Normalized() {
        let n = Vec2(3, 4).normalized
        #expect(abs(n.length - 1.0) < 1e-12)
        #expect(Vec2.zero.normalized == .zero)
    }

    @Test func eulerIntegration() {
        // dy/dt = 2, y(0)=0, dt=1 → y=2
        let result = Integrator.euler(state: 0.0, t: 0, dt: 1.0) { _, _ in 2.0 }
        #expect(abs(result - 2.0) < 1e-12)
    }

    @Test func rk4Accuracy() {
        // dy/dt = y, y(0)=1 → y(1) = e
        var y = 1.0
        let steps = 100; let dt = 1.0 / Double(steps)
        for i in 0..<steps {
            y = Integrator.rk4(state: y, t: Double(i) * dt, dt: dt) { _, s in s }
        }
        #expect(abs(y - 2.718281828459045) < 1e-10, "RK4 should approximate e")
    }

    @Test func trapezoidIntegration() {
        // ∫₀¹ x² dx = 1/3
        let result = Integrator.trapezoid(from: 0, to: 1, steps: 1000) { $0 * $0 }
        #expect(abs(result - 1.0 / 3.0) < 1e-6)
    }

    @Test func aabbOverlap() {
        let a = AABB(center: Vec2(0, 0), halfSize: Vec2(1, 1))
        let b = AABB(center: Vec2(1.5, 0), halfSize: Vec2(1, 1))
        let c = AABB(center: Vec2(3, 0), halfSize: Vec2(1, 1))
        #expect(a.overlaps(b))
        #expect(!a.overlaps(c))
    }

    @Test func particleSystemGroundCollision() {
        var system = ParticleSystem(gravity: Vec2(0, -10), groundY: 0)
        system.addParticle(Particle(position: Vec2(0, 5)))
        for _ in 0..<600 { system.step(dt: 1.0 / 60.0) }
        #expect(system.particles[0].position.y >= 0.0)
    }

    @Test func springRelaxation() {
        var particles = [Particle(position: Vec2(0, 0)), Particle(position: Vec2(3, 0))]
        let spring = Spring(a: 0, b: 1, restLength: 2.0)
        for _ in 0..<100 { spring.apply(to: &particles) }
        let dist = (particles[1].position - particles[0].position).length
        #expect(abs(dist - 2.0) < 1e-6)
    }
}

// MARK: - HPC Tests

@Suite("HPC")
struct HPCTests {

    @Test func simdMultiplyAdd() {
        let r = SIMDOps.multiplyAdd([1,2,3,4], [2,2,2,2], [10,10,10,10])
        #expect(r == SIMD4<Float>(12, 14, 16, 18))
    }

    @Test func simdDot() {
        let a: SIMD8<Float> = [1,0,0,0,0,0,0,0]
        let b: SIMD8<Float> = [5,3,0,0,0,0,0,0]
        #expect(SIMDOps.dot(a, b) == 5.0)
    }

    @Test func simdNormalize() {
        let n = SIMDOps.normalize(SIMD3<Double>(3, 0, 4))
        let len = (n * n).sum().squareRoot()
        #expect(abs(len - 1.0) < 1e-12)
        #expect(SIMDOps.normalize(.zero) == .zero)
    }

    @Test func batchDot() {
        let a: [Float] = [1, 2, 3, 4, 5]
        let b: [Float] = [2, 2, 2, 2, 2]
        #expect(SIMDOps.batchDot(a, b) == 30.0)
    }

    @Test func concurrentMap() {
        let input = Array(0..<100)
        let result = ParallelProcessing.concurrentMap(input) { $0 * 2 }
        #expect(result == input.map { $0 * 2 })
    }

    @Test func concurrentReduce() {
        let input = Array(1...1000)
        let result = ParallelProcessing.concurrentReduce(input, initial: 0, chunkSize: 100) { $0 + $1 }
        #expect(result == 500500)
    }

    @Test func alignedBuffer() {
        let buf = MemoryOptimization.AlignedBuffer<Float>(count: 4)
        for i in 0..<4 { buf[i] = Float(i) }
        #expect(buf[2] == 2.0)
        #expect(buf.count == 4)
    }
}

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

// MARK: - Performance Testing Patterns
// Swift Testing doesn't have built-in measure{} — use Clock for manual benchmarks.

@Suite("Performance")
struct PerformancePatternTests {

    @Test func vec2ArithmeticThroughput() {
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            var v = Vec2(1, 1)
            for _ in 0..<100_000 { v = v + Vec2(0.001, 0.001) }
            _ = v
        }
        // Sanity: should complete in well under 1 second
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

// MARK: - Smoke Test

@Test func version() {
    #expect(SwiftTemplate.version == "0.1.0")
}

#elseif canImport(XCTest)
import XCTest
@testable import SwiftTemplate

// MARK: - XCTest Fallback (abridged — covers key patterns)

final class BestPracticesTests: XCTestCase {
    func testPoint2D() { XCTAssertEqual(Point2D(x: 1, y: 2), Point2D(x: 1, y: 2)) }
    func testCOWBuffer() {
        var a = COWBuffer([1, 2, 3]); var b = a; b[0] = 99
        XCTAssertEqual(a[0], 1); XCTAssertEqual(b[0], 99)
    }
    func testConfig() throws {
        let c = Config(["k": "v"]); XCTAssertEqual(try c.require("k"), "v")
    }
    func testClamped() {
        var s = AudioSettings(); s.volume = 1.5; XCTAssertEqual(s.volume, 1.0)
    }
}

final class SimulationTests: XCTestCase {
    func testVec2() { XCTAssertEqual(Vec2(3, 4) + Vec2(1, 2), Vec2(4, 6)) }
    func testVec2Length() { XCTAssertEqual(Vec2(3, 4).length, 5.0, accuracy: 1e-12) }
    func testRK4() {
        var y = 1.0; let dt = 0.01
        for i in 0..<100 { y = Integrator.rk4(state: y, t: Double(i)*dt, dt: dt) { _, s in s } }
        XCTAssertEqual(y, 2.718281828459045, accuracy: 1e-10)
    }
    func testTrapezoid() {
        let r = Integrator.trapezoid(from: 0, to: 1, steps: 1000) { $0 * $0 }
        XCTAssertEqual(r, 1.0/3.0, accuracy: 1e-6)
    }
    func testAABB() {
        let a = AABB(center: Vec2(0,0), halfSize: Vec2(1,1))
        let b = AABB(center: Vec2(1.5,0), halfSize: Vec2(1,1))
        XCTAssertTrue(a.overlaps(b))
    }
}

final class HPCTests: XCTestCase {
    func testBatchDot() { XCTAssertEqual(SIMDOps.batchDot([1,2,3,4,5], [2,2,2,2,2]), 30.0) }
    func testConcurrentMap() {
        let r = ParallelProcessing.concurrentMap(Array(0..<50)) { $0 * 2 }
        XCTAssertEqual(r, (0..<50).map { $0 * 2 })
    }
}

final class ConcurrencyTests: XCTestCase {
    func testCounter() async {
        let c = Counter(0); let v = await c.increment(by: 5); XCTAssertEqual(v, 5)
    }
    func testParallelMap() async throws {
        let r = try await StructuredConcurrency.parallelMap([1,2,3]) { $0 * $0 }
        XCTAssertEqual(r, [1, 4, 9])
    }
}

final class PerformanceTests: XCTestCase {
    func testVec2Performance() {
        measure {
            var v = Vec2(1,1); for _ in 0..<100_000 { v = v + Vec2(0.001, 0.001) }; _ = v
        }
    }
    func testBatchDotPerformance() {
        let a = [Float](repeating: 1, count: 10_000), b = [Float](repeating: 2, count: 10_000)
        measure { _ = SIMDOps.batchDot(a, b) }
    }
}

final class SmokeTests: XCTestCase {
    func testVersion() { XCTAssertEqual(SwiftTemplate.version, "0.1.0") }
}
#endif
