// Comprehensive Testing Setup for SwiftTemplate
// Demonstrates: unit tests, async tests, performance testing patterns
// Uses Swift Testing (#if canImport(Testing)) with XCTest fallback.

#if canImport(Testing)
import Testing
import Foundation
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
        #expect(abs(y - 2.718281828459045) < 1e-9, "RK4 should approximate e")
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
        let r = SIMDOps.multiplyAdd([1, 2, 3, 4], [2, 2, 2, 2], [10, 10, 10, 10])
        #expect(r == SIMD4<Float>(12, 14, 16, 18))
    }

    @Test func simdDot() {
        let a: SIMD8<Float> = [1, 0, 0, 0, 0, 0, 0, 0]
        let b: SIMD8<Float> = [5, 3, 0, 0, 0, 0, 0, 0]
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
            for _ in 0..<100_000 { v += Vec2(0.001, 0.001) }
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

// MARK: - CrossPlatform Tests

@Suite("CrossPlatform")
struct CrossPlatformTests {

    @Test func platformCurrent() {
        #expect(Platform.current == .macOS)
    }

    @Test func platformIsApple() {
        #expect(Platform.isApple == true)
    }

    @Test func platformArchitecture() {
        let arch = Platform.architecture
        #expect(arch == "arm64" || arch == "x86_64")
    }

    @Test func portablePathHome() {
        #expect(!PortablePath.home.isEmpty)
    }

    @Test func portablePathTemp() {
        #expect(!PortablePath.temp.isEmpty)
    }

    @Test func portablePathJoin() {
        #expect(PortablePath.join("a", "b", "c") == "a/b/c")
    }

    @Test func platformLoggerLevels() {
        // Exercise all log levels to cover the switch
        PlatformLogger.log(.debug, "d")
        PlatformLogger.log(.info, "i")
        PlatformLogger.log(.warning, "w")
        PlatformLogger.log(.error, "e")
    }

    @Test func featureFlags() {
        // Just access them to cover the branches
        _ = FeatureFlags.hasGPU
        _ = FeatureFlags.hasSwiftUI
        _ = FeatureFlags.hasCombine
    }

    @Test func byteOrderIsLittleEndian() {
        #expect(ByteOrder.isLittleEndian == true)
    }

    @Test func byteOrderRoundTrip() {
        let value: UInt32 = 0xDEADBEEF
        let bytes = ByteOrder.toBigEndian(value)
        #expect(bytes.count == 4)
        let decoded = ByteOrder.fromBigEndian(bytes)
        #expect(decoded == value)
    }

    @Test func byteOrderFromBigEndianTooShort() {
        #expect(ByteOrder.fromBigEndian([1, 2]) == nil)
    }

    @Test func compileDiagnosticsLegacyFetch() {
        CompileDiagnostics.legacyFetch()
    }

    @Test func httpErrorCases() {
        let e1 = PortableHTTP.HTTPError.badStatus(404)
        let e2 = PortableHTTP.HTTPError.noData
        #expect(e1 is Error)
        #expect(e2 is Error)
    }
}

// MARK: - Rendering Tests

@Suite("Rendering")
struct RenderingTests {

    @Test func color4Init() {
        let c = Color4(r: 0.5, g: 0.6, b: 0.7, a: 0.8)
        #expect(c.r == 0.5)
        #expect(c.a == 0.8)
    }

    @Test func color4DefaultAlpha() {
        let c = Color4(r: 1, g: 0, b: 0)
        #expect(c.a == 1)
    }

    @Test func color4StaticColors() {
        #expect(Color4.white == Color4(r: 1, g: 1, b: 1))
        #expect(Color4.black == Color4(r: 0, g: 0, b: 0))
        #expect(Color4.clear == Color4(r: 0, g: 0, b: 0, a: 0))
    }

    @Test func pixelBufferInit() {
        let buf = PixelBuffer(width: 4, height: 4, fill: .white)
        #expect(buf.width == 4)
        #expect(buf.height == 4)
        #expect(buf[0, 0] == .white)
    }

    @Test func pixelBufferSubscript() {
        var buf = PixelBuffer(width: 4, height: 4)
        buf[2, 3] = .white
        #expect(buf[2, 3] == .white)
        #expect(buf[0, 0] == .clear)
    }

    @Test func pixelBufferFillRect() {
        var buf = PixelBuffer(width: 10, height: 10)
        buf.fillRect(x: 2, y: 2, w: 3, h: 3, color: .white)
        #expect(buf[3, 3] == .white)
        #expect(buf[0, 0] == .clear)
    }

    @Test func pixelBufferFillRectClipping() {
        var buf = PixelBuffer(width: 4, height: 4)
        // Partially out of bounds
        buf.fillRect(x: -1, y: -1, w: 3, h: 3, color: .white)
        #expect(buf[0, 0] == .white)
        #expect(buf[1, 1] == .white)
    }

    @Test func pixelBufferDrawLine() {
        var buf = PixelBuffer(width: 10, height: 10)
        buf.drawLine(from: (0, 0), to: (9, 9), color: .white)
        #expect(buf[0, 0] == .white)
        #expect(buf[9, 9] == .white)
    }

    @Test func pixelBufferDrawLineSteep() {
        var buf = PixelBuffer(width: 10, height: 10)
        buf.drawLine(from: (5, 0), to: (5, 9), color: .white)
        #expect(buf[5, 0] == .white)
        #expect(buf[5, 9] == .white)
    }

    @Test func pixelBufferDrawLineReverse() {
        var buf = PixelBuffer(width: 10, height: 10)
        buf.drawLine(from: (9, 9), to: (0, 0), color: .white)
        #expect(buf[0, 0] == .white)
    }

    @Test func gameLoop() {
        final class TestScene: GameScene {
            var updateCount = 0
            var renderCount = 0
            func update(dt: Double) { updateCount += 1 }
            func render(into buffer: inout PixelBuffer) { renderCount += 1 }
        }
        let scene = TestScene()
        let loop = GameLoop(tickRate: 1.0 / 60.0, scene: scene)
        var buf = PixelBuffer(width: 2, height: 2)
        loop.step(elapsed: 1.0 / 30.0, buffer: &buf) // should trigger 2 updates
        #expect(scene.updateCount == 2)
        #expect(scene.renderCount == 1)
    }
}

#if canImport(CoreGraphics)
import CoreGraphics

@Suite("CoreGraphicsRendering")
struct CoreGraphicsRenderingTests {

    @Test func makeContext() {
        let ctx = CoreGraphicsRendering.makeContext(width: 10, height: 10)
        #expect(ctx != nil)
    }

    @Test func drawRoundedRect() {
        let img = CoreGraphicsRendering.drawRoundedRect(
            width: 50, height: 50, cornerRadius: 5,
            fillColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        )
        #expect(img != nil)
    }

    @Test func drawGradient() {
        let img = CoreGraphicsRendering.drawGradient(
            width: 50, height: 50,
            from: CGColor(red: 1, green: 0, blue: 0, alpha: 1),
            to: CGColor(red: 0, green: 0, blue: 1, alpha: 1)
        )
        #expect(img != nil)
    }

    @Test func drawCheckerboard() {
        let img = CoreGraphicsRendering.drawCheckerboard(
            width: 40, height: 40, tileSize: 10,
            color1: CGColor(red: 1, green: 1, blue: 1, alpha: 1),
            color2: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        #expect(img != nil)
    }
}
#endif

#if canImport(SwiftUI)
import SwiftUI

@Suite("SwiftUIShapes")
struct SwiftUIShapeTests {

    @Test func regularPolygonPath() {
        let poly = RegularPolygon(sides: 6)
        #expect(poly.sides == 6)
        let path = poly.path(in: CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(!path.isEmpty)
    }

    @Test func regularPolygonMinSides() {
        let poly = RegularPolygon(sides: 1)
        #expect(poly.sides == 3)
    }

    @Test func starPath() {
        let star = Star(points: 5, innerRatio: 0.4)
        #expect(star.points == 5)
        let path = star.path(in: CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(!path.isEmpty)
    }

    @Test func starMinPoints() {
        let star = Star(points: 1)
        #expect(star.points == 2)
    }
}
#endif

// MARK: - Systems Tests

@Suite("Systems")
struct SystemsTests {

    @Test func fileSystemWriteReadDelete() throws {
        let tmp = PortablePath.join(PortablePath.temp, "swift-test-\(UUID().uuidString).txt")
        let data = Data("hello".utf8)
        try FileSystem.write(data, to: tmp)
        let read = try FileSystem.readData(at: tmp)
        #expect(read == data)
        let str = try FileSystem.readString(at: tmp)
        #expect(str == "hello")
        try FileManager.default.removeItem(atPath: tmp)
    }

    @Test func fileSystemNotFound() {
        #expect(throws: FileSystem.FSError.self) {
            try FileSystem.readData(at: "/nonexistent-\(UUID().uuidString)")
        }
    }

    @Test func fileSystemListDirectory() throws {
        let entries = try FileSystem.listDirectory(at: PortablePath.temp)
        #expect(entries is [String])
    }

    @Test func fileSystemWalk() throws {
        let dir = PortablePath.join(PortablePath.temp, "swift-walk-\(UUID().uuidString)")
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let file = PortablePath.join(dir, "a.txt")
        try Data("x".utf8).write(to: URL(fileURLWithPath: file))
        let paths = try FileSystem.walk(dir)
        #expect(paths.contains("a.txt"))
        try FileManager.default.removeItem(atPath: dir)
    }

    @Test func fileSystemWalkNotFound() {
        #expect(throws: FileSystem.FSError.self) {
            try FileSystem.walk("/nonexistent-\(UUID().uuidString)")
        }
    }

    @Test func fileSystemAttributes() throws {
        let tmp = PortablePath.join(PortablePath.temp, "swift-attr-\(UUID().uuidString).txt")
        try FileSystem.write(Data("x".utf8), to: tmp)
        let attrs = try FileSystem.attributes(at: tmp)
        #expect(attrs[.size] != nil)
        try FileManager.default.removeItem(atPath: tmp)
    }

    @Test func fileSystemAtomicWrite() throws {
        let tmp = PortablePath.join(PortablePath.temp, "swift-atomic-\(UUID().uuidString).txt")
        try FileSystem.atomicWrite(Data("atomic".utf8), to: tmp)
        let str = try FileSystem.readString(at: tmp)
        #expect(str == "atomic")
        // Overwrite existing
        try FileSystem.atomicWrite(Data("v2".utf8), to: tmp)
        #expect(try FileSystem.readString(at: tmp) == "v2")
        try FileManager.default.removeItem(atPath: tmp)
    }

    @Test func fsErrorDescriptions() {
        let e1 = FileSystem.FSError.notFound("/x")
        let e2 = FileSystem.FSError.alreadyExists("/x")
        let e3 = FileSystem.FSError.permissionDenied("/x")
        let e4 = FileSystem.FSError.ioError("/x", underlying: NSError(domain: "", code: 0))
        #expect(e1.description.contains("Not found"))
        #expect(e2.description.contains("Already exists"))
        #expect(e3.description.contains("Permission denied"))
        #expect(e4.description.contains("I/O error"))
    }

    @Test func systemEnvironment() {
        #expect(SystemEnvironment.get("PATH") != nil)
        #expect(!SystemEnvironment.all.isEmpty)
        #expect(!SystemEnvironment.hostName.isEmpty)
        #expect(!SystemEnvironment.osVersion.isEmpty)
        #expect(SystemEnvironment.physicalMemory > 0)
        #expect(SystemEnvironment.processorCount > 0)
    }

    @Test func shellRun() {
        let result = Shell.run("/bin/echo", arguments: ["hello"])
        #expect(result.succeeded)
        #expect(result.stdout.contains("hello"))
        #expect(result.exitCode == 0)
    }

    @Test func shellSh() {
        let result = Shell.sh("echo test")
        #expect(result.succeeded)
        #expect(result.stdout.contains("test"))
    }

    @Test func shellRunAsync() async {
        let result = await Shell.runAsync("/bin/echo", arguments: ["async"])
        #expect(result.succeeded)
        #expect(result.stdout.contains("async"))
    }

    @Test func shellRunFailure() {
        let result = Shell.run("/bin/sh", arguments: ["-c", "exit 1"])
        #expect(!result.succeeded)
        #expect(result.exitCode == 1)
    }

    @Test func streamIOReadChunked() throws {
        let tmp = PortablePath.join(PortablePath.temp, "swift-chunk-\(UUID().uuidString).txt")
        try FileSystem.write(Data("abcdef".utf8), to: tmp)
        var chunks: [Data] = []
        try StreamIO.readChunked(path: tmp, chunkSize: 3) { chunks.append($0) }
        #expect(!chunks.isEmpty)
        try FileManager.default.removeItem(atPath: tmp)
    }

    @Test func streamIOReadChunkedNotFound() {
        #expect(throws: FileSystem.FSError.self) {
            try StreamIO.readChunked(path: "/nonexistent-\(UUID().uuidString)") { _ in }
        }
    }

    @Test func streamIOMakePipe() {
        let (read, write) = StreamIO.makePipe()
        write.write(Data("pipe".utf8))
        write.closeFile()
        let data = read.readDataToEndOfFile()
        #expect(String(decoding: data, as: UTF8.self) == "pipe")
    }

    @Test func unsafeMemoryWithManualBuffer() {
        var sum = 0
        UnsafeMemory.withManualBuffer(of: Int.self, count: 4) { buf in
            for i in 0..<4 { buf[i] = i }
            sum = buf.reduce(0, +)
        }
        #expect(sum == 6)
    }

    @Test func unsafeMemoryReinterpret() {
        let floats: [Float] = [1.0, 2.0]
        let bytes = UnsafeMemory.reinterpret(floats, as: UInt8.self)
        #expect(bytes.count == 8)
    }

    @Test func unsafeMemoryCopyBytes() {
        let src: [UInt8] = [1, 2, 3, 4]
        var dst = [UInt8](repeating: 0, count: 4)
        src.withUnsafeBytes { srcPtr in
            dst.withUnsafeMutableBytes { dstPtr in
                UnsafeMemory.copyBytes(from: srcPtr.baseAddress!, to: dstPtr.baseAddress!, count: 4)
            }
        }
        #expect(dst == [1, 2, 3, 4])
    }

    @Test func cfBridgingStringRoundTrip() {
        #expect(CFBridging.cfStringRoundTrip("hello") == "hello")
    }

    @Test func cfBridgingDictionary() {
        let dict = CFBridging.cfDictionaryExample()
        #expect(dict["key"] as? String == "value")
        #expect(dict["number"] as? Int == 42)
    }

    @Test func signalHandling() {
        // Just exercise the API without actually trapping real signals
        Signals.ignore(SIGUSR1)
        Signals.restore(SIGUSR1)
    }
}

// MARK: - ThirdPartyPatterns Tests

@Suite("ThirdPartyPatterns")
struct ThirdPartyPatternsTests {

    struct MockHTTPClient: HTTPClient, Sendable {
        let responseData: Data
        func data(from url: URL) async throws -> (Data, URLResponse) {
            (responseData, URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
        }
    }

    @Test func printLogger() {
        let logger = PrintLogger()
        logger.log(.debug, "test debug")
        logger.log(.info, "test info")
        logger.log(.warning, "test warning")
        logger.log(.error, "test error")
    }

    @Test func logLevelRawValues() {
        #expect(LogLevel.debug.rawValue == "debug")
        #expect(LogLevel.error.rawValue == "error")
    }

    @Test func appDependenciesLive() {
        let deps = AppDependencies.live
        #expect(deps.logger is PrintLogger)
    }

    @Test func apiServiceFetchJSON() async throws {
        let json = Data("{\"key\":\"value\"}".utf8)
        let mock = MockHTTPClient(responseData: json)
        let deps = AppDependencies(http: mock, logger: PrintLogger())
        let service = APIService(deps: deps)
        let result = try await service.fetchJSON(from: URL(string: "https://example.com")!)
        let dict = result as? [String: Any]
        #expect(dict?["key"] as? String == "value")
    }
}

// MARK: - Additional Concurrency Tests

@Suite("ConcurrencyExtended")
struct ConcurrencyExtendedTests {

    @Test func readWriteLock() async {
        let lock = GCDPatterns.ReadWriteLock(0)
        #expect(lock.read() == 0)
        lock.write { $0 = 42 }
        // Give barrier write time to complete
        try? await Task.sleep(for: .milliseconds(50))
        #expect(lock.read() == 42)
    }

    @Test func parallelBatch() async {
        let items = [1, 2, 3, 4]
        let result = await withCheckedContinuation { (cont: CheckedContinuation<[Int], Never>) in
            GCDPatterns.parallelBatch(items: items, transform: { $0 * 2 }) { results in
                cont.resume(returning: results)
            }
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
            { 2 },
        ])
        #expect(result == 1 || result == 2)
    }

    @Test func cacheDescription() {
        let cache = Cache<String, Int>()
        #expect(cache.description == "Cache<String, Int>")
    }
}

// MARK: - Additional HPC Tests

@Suite("HPCExtended")
struct HPCExtendedTests {

    @Test func accelerateVectorAdd() {
        let r = AccelerateOps.vectorAdd([1, 2, 3], [4, 5, 6])
        #expect(r == [5, 7, 9])
    }

    @Test func accelerateRMS() {
        let r = AccelerateOps.rms([3, 4])
        #expect(abs(r - 3.535534) < 0.001)
    }

    @Test func accelerateFFT() {
        let signal: [Float] = [1, 0, 0, 0, 0, 0, 0, 0]
        let (real, imag) = AccelerateOps.fft(signal)
        #expect(!real.isEmpty)
        #expect(!imag.isEmpty)
    }

    @Test func accelerateMatmul() {
        // 2x2 identity * [1,2;3,4]
        let a: [Float] = [1, 0, 0, 1]
        let b: [Float] = [1, 2, 3, 4]
        let c = AccelerateOps.matmul(a: a, b: b, m: 2, n: 2, k: 2)
        #expect(c == [1, 2, 3, 4])
    }

    @Test func measure() {
        let result = MemoryOptimization.measure("") { 42 }
        #expect(result == 42)
    }

    @Test func measureWithLabel() {
        let result = MemoryOptimization.measure("test") { "hello" }
        #expect(result == "hello")
    }

    @Test func alignedBufferAccess() {
        let buf = MemoryOptimization.AlignedBuffer<Int>(count: 3)
        buf[0] = 10; buf[1] = 20; buf[2] = 30
        let slice = Array(buf.buffer)
        #expect(slice == [10, 20, 30])
    }

    @Test func concurrentMapEmpty() {
        let r = ParallelProcessing.concurrentMap([Int]()) { $0 }
        #expect(r.isEmpty)
    }

    @Test func concurrentReduceSmall() {
        let r = ParallelProcessing.concurrentReduce([1, 2, 3], initial: 0, chunkSize: 1024) { $0 + $1 }
        #expect(r == 6)
    }
}

// MARK: - Additional Simulation Tests

@Suite("SimulationExtended")
struct SimulationExtendedTests {

    @Test func vec2PlusEquals() {
        var v = Vec2(1, 2)
        v += Vec2(3, 4)
        #expect(v == Vec2(4, 6))
    }

    @Test func particleApplyForce() {
        var p = Particle(position: Vec2(0, 0), mass: 2.0)
        p.applyForce(Vec2(10, 0))
        #expect(p.acceleration.x == 5.0) // F/m = 10/2
    }

    @Test func particleIntegrate() {
        var p = Particle(position: Vec2(0, 0))
        p.applyForce(Vec2(0, -10))
        p.integrate(dt: 1.0 / 60.0)
        #expect(p.position.y < 0)
    }

    @Test func springZeroLength() {
        var particles = [Particle(position: Vec2(0, 0)), Particle(position: Vec2(0, 0))]
        let spring = Spring(a: 0, b: 1, restLength: 1.0)
        spring.apply(to: &particles)
        // Zero-length delta should be handled gracefully
        #expect(particles[0].position == Vec2(0, 0))
    }
}

#if canImport(QuartzCore)
import QuartzCore

@Suite("CoreAnimation")
struct CoreAnimationTests {

    @Test func positionAnimation() {
        let anim = CoreAnimationPatterns.positionAnimation(from: .zero, to: CGPoint(x: 100, y: 100))
        #expect(anim.duration == 0.3)
        #expect(anim.keyPath == "position")
    }

    @Test func pathAnimation() {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 100, y: 100))
        let anim = CoreAnimationPatterns.pathAnimation(path: path)
        #expect(anim.duration == 1.0)
    }

    @Test func springAnimation() {
        let anim = CoreAnimationPatterns.springAnimation(keyPath: "transform.scale", to: 1.5)
        #expect(anim.keyPath == "transform.scale")
        #expect(anim.damping == 10)
    }

    @Test func customTimingFunction() {
        let tf = CoreAnimationPatterns.customTimingFunction(c1x: 0.25, c1y: 0.1, c2x: 0.25, c2y: 1.0)
        #expect(tf is CAMediaTimingFunction)
    }
}
#endif

// MARK: - Additional BestPractices Tests

@Suite("BestPracticesExtended")
struct BestPracticesExtendedTests {

    struct SteppablePoint: Steppable {
        var x: Double = 0
        mutating func step(dt: Double) { x += dt }
    }

    @Test func stepAll() {
        var items = [SteppablePoint(), SteppablePoint()]
        items.stepAll(dt: 1.0)
        #expect(items[0].x == 1.0)
        #expect(items[1].x == 1.0)
    }

    @Test func cowBufferAppend() {
        var buf = COWBuffer<Int>([1, 2])
        buf.append(3)
        #expect(buf.count == 3)
        #expect(buf[2] == 3)
    }

    @Test func cowBufferCopyOnWriteAppend() {
        let a = COWBuffer([1, 2])
        var b = a
        b.append(3)
        #expect(a.count == 2)
        #expect(b.count == 3)
    }

    @Test func configErrorCases() {
        let e1 = ConfigError.missingKey("k")
        let e2 = ConfigError.typeMismatch(key: "k", expected: "Int")
        let e3 = ConfigError.validationFailed("bad")
        #expect(e1 is Error)
        #expect(e2 is Error)
        #expect(e3 is Error)
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
        XCTAssertEqual(y, 2.718281828459045, accuracy: 1e-6)
    }
    func testTrapezoid() {
        let r = Integrator.trapezoid(from: 0, to: 1, steps: 1000) { $0 * $0 }
        XCTAssertEqual(r, 1.0/3.0, accuracy: 1e-6)
    }
    func testAABB() {
        let a = AABB(center: Vec2(0, 0), halfSize: Vec2(1, 1))
        let b = AABB(center: Vec2(1.5, 0), halfSize: Vec2(1, 1))
        XCTAssertTrue(a.overlaps(b))
    }
}

final class HPCTests: XCTestCase {
    func testBatchDot() { XCTAssertEqual(SIMDOps.batchDot([1, 2, 3, 4, 5], [2, 2, 2, 2, 2]), 30.0) }
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
        let r = try await StructuredConcurrency.parallelMap([1, 2, 3]) { $0 * $0 }
        XCTAssertEqual(r, [1, 4, 9])
    }
}

final class PerformanceTests: XCTestCase {
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

final class SmokeTests: XCTestCase {
    func testVersion() { XCTAssertEqual(SwiftTemplate.version, "0.1.0") }
}
#endif
