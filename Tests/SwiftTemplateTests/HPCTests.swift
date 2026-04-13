#if canImport(Testing)
import Testing
import Foundation
@testable import SwiftTemplate

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

#elseif canImport(XCTest)
import XCTest
@testable import SwiftTemplate

final class HPCXCTests: XCTestCase {
    func testBatchDot() { XCTAssertEqual(SIMDOps.batchDot([1, 2, 3, 4, 5], [2, 2, 2, 2, 2]), 30.0) }
    func testBatchDotEmpty() { XCTAssertEqual(SIMDOps.batchDot([], []), 0.0) }
    func testBatchDotMismatch() { XCTAssertEqual(SIMDOps.batchDot([1, 2], [1]), 0.0) }
    func testBatchSum() { XCTAssertEqual(SIMDOps.batchSum([1, 2, 3, 4, 5]), 15.0) }
    func testBatchSumEmpty() { XCTAssertEqual(SIMDOps.batchSum([]), 0.0) }
    func testConcurrentMap() {
        let r = ParallelProcessing.concurrentMap(Array(0..<50)) { $0 * 2 }
        XCTAssertEqual(r, (0..<50).map { $0 * 2 })
    }
    func testConcurrentMapEmpty() {
        let r = ParallelProcessing.concurrentMap([Int]()) { $0 }
        XCTAssertTrue(r.isEmpty)
    }
    func testConcurrentReduce() {
        let r = ParallelProcessing.concurrentReduce([1, 2, 3], initial: 0, chunkSize: 1024) { $0 + $1 }
        XCTAssertEqual(r, 6)
    }
    func testMatmul() {
        let a: [Float] = [1, 0, 0, 1], b: [Float] = [1, 2, 3, 4]
        let c = AccelerateOps.matmul(a: a, b: b, m: 2, n: 2, k: 2)
        XCTAssertEqual(c, [1, 2, 3, 4])
    }
    func testMeasure() {
        let r = MemoryOptimization.measure("") { 42 }
        XCTAssertEqual(r, 42)
    }
    func testAlignedBuffer() {
        let buf = MemoryOptimization.AlignedBuffer<Int>(count: 3)
        buf[0] = 10; buf[1] = 20; buf[2] = 30
        XCTAssertEqual(Array(buf.buffer), [10, 20, 30])
    }
}
#endif
