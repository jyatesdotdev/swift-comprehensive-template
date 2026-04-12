// MARK: - HPC Module
// SIMD, Accelerate, parallel processing, optimization techniques

import Foundation

// MARK: - 1. SIMD Operations

/// Demonstrates Swift's built-in SIMD types for vectorized computation.
public enum SIMDOps {

    /// Element-wise multiply-add: `a * b + c` using SIMD4.
    ///
    /// - Parameters:
    ///   - a: First operand.
    ///   - b: Second operand (multiplied with `a`).
    ///   - c: Addend.
    /// - Returns: The fused multiply-add result.
    @inlinable
    public static func multiplyAdd(
        _ a: SIMD4<Float>, _ b: SIMD4<Float>, _ c: SIMD4<Float>
    ) -> SIMD4<Float> {
        a * b + c
    }

    /// Dot product of two SIMD8 vectors.
    ///
    /// - Parameters:
    ///   - a: First vector.
    ///   - b: Second vector.
    /// - Returns: The scalar dot product.
    @inlinable
    public static func dot(_ a: SIMD8<Float>, _ b: SIMD8<Float>) -> Float {
        (a * b).sum()
    }

    /// Normalizes a 3D vector to unit length.
    ///
    /// - Parameter v: The vector to normalize.
    /// - Returns: A unit vector, or `.zero` if the input length is near zero.
    @inlinable
    public static func normalize(_ v: SIMD3<Double>) -> SIMD3<Double> {
        let len = (v * v).sum().squareRoot()
        guard len > .ulpOfOne else { return .zero }
        return v / len
    }

    /// Batch dot product over aligned arrays using SIMD4 chunks.
    ///
    /// - Parameters:
    ///   - a: First array of floats.
    ///   - b: Second array of floats (must be same length as `a`).
    /// - Returns: The dot product of the two arrays.
    public static func batchDot(_ a: [Float], _ b: [Float]) -> Float {
        precondition(a.count == b.count)
        let n = a.count
        let chunks = n / 4
        var acc = SIMD4<Float>.zero
        for i in 0..<chunks {
            let va = SIMD4(a[i*4], a[i*4+1], a[i*4+2], a[i*4+3])
            let vb = SIMD4(b[i*4], b[i*4+1], b[i*4+2], b[i*4+3])
            acc += va * vb
        }
        var result = acc.sum()
        for i in (chunks * 4)..<n {
            result += a[i] * b[i]
        }
        return result
    }
}

// MARK: - 2. Accelerate Framework

#if canImport(Accelerate)
import Accelerate

/// Demonstrates vDSP and BLAS via the Accelerate framework.
public enum AccelerateOps {

    // MARK: vDSP

    /// Element-wise vector addition using vDSP.
    ///
    /// - Parameters:
    ///   - a: First input vector.
    ///   - b: Second input vector (same length as `a`).
    /// - Returns: The element-wise sum.
    public static func vectorAdd(_ a: [Float], _ b: [Float]) -> [Float] {
        precondition(a.count == b.count)
        return vDSP.add(a, b)
    }

    /// Root-mean-square of a signal.
    ///
    /// - Parameter signal: The input samples.
    /// - Returns: The RMS value.
    public static func rms(_ signal: [Float]) -> Float {
        var result: Float = 0
        vDSP_rmsqv(signal, 1, &result, vDSP_Length(signal.count))
        return result
    }

    /// Fast Fourier Transform (forward, real-to-complex).
    ///
    /// - Parameter signal: The input signal (length should be a power of 2).
    /// - Returns: A tuple of real and imaginary components.
    public static func fft(_ signal: [Float]) -> (real: [Float], imaginary: [Float]) {
        let n = signal.count
        let log2n = vDSP_Length(log2(Float(n)))
        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return ([], [])
        }
        defer { vDSP_destroy_fftsetup(setup) }

        var real = [Float](repeating: 0, count: n / 2)
        var imag = [Float](repeating: 0, count: n / 2)
        real.withUnsafeMutableBufferPointer { rBuf in
            imag.withUnsafeMutableBufferPointer { iBuf in
                var split = DSPSplitComplex(realp: rBuf.baseAddress!, imagp: iBuf.baseAddress!)
                signal.withUnsafeBufferPointer { sBuf in
                    sBuf.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: n / 2) { ptr in
                        vDSP_ctoz(ptr, 2, &split, 1, vDSP_Length(n / 2))
                    }
                }
                vDSP_fft_zrip(setup, &split, 1, log2n, FFTDirection(kFFTDirection_Forward))
            }
        }
        return (real, imag)
    }

    // MARK: BLAS

    /// Matrix multiply (`C = A × B`) using `cblas_sgemm`.
    ///
    /// - Parameters:
    ///   - a: Matrix A in row-major layout (M×K).
    ///   - b: Matrix B in row-major layout (K×N).
    ///   - m: Number of rows in A / C.
    ///   - n: Number of columns in B / C.
    ///   - k: Number of columns in A / rows in B.
    /// - Returns: The M×N result matrix in row-major layout.
    public static func matmul(
        a: [Float], b: [Float], m: Int, n: Int, k: Int
    ) -> [Float] {
        var c = [Float](repeating: 0, count: m * n)
        // Note: cblas_sgemm deprecated in macOS 13.3 in favor of ILP64 variant.
        // Compile with -DACCELERATE_NEW_LAPACK for the updated headers.
        cblas_sgemm(
            CblasRowMajor, CblasNoTrans, CblasNoTrans,
            Int32(m), Int32(n), Int32(k),
            1.0, a, Int32(k), b, Int32(n),
            0.0, &c, Int32(n)
        )
        return c
    }
}
#endif

// MARK: - 3. Parallel Processing

/// Parallel processing utilities using concurrentPerform.
public enum ParallelProcessing {

    /// Parallel map using `DispatchQueue.concurrentPerform` (GCD-based, no async).
    ///
    /// - Parameters:
    ///   - items: The input collection.
    ///   - transform: A sendable closure applied to each element.
    /// - Returns: An array of transformed results in the original order.
    public static func concurrentMap<T: Sendable, R: Sendable>(
        _ items: [T],
        transform: @Sendable (T) -> R
    ) -> [R] {
        let count = items.count
        guard count > 0 else { return [] }
        nonisolated(unsafe) let results = UnsafeMutableBufferPointer<R>.allocate(capacity: count)
        DispatchQueue.concurrentPerform(iterations: count) { i in
            results[i] = transform(items[i])
        }
        let array = Array(results)
        results.deallocate()
        return array
    }

    /// Parallel reduce: split array into chunks, reduce each in parallel, then combine.
    ///
    /// - Parameters:
    ///   - items: The input collection.
    ///   - initial: The identity element for the reduction.
    ///   - chunkSize: Elements per parallel chunk. Defaults to `1024`.
    ///   - combine: A sendable associative combining function.
    /// - Returns: The reduced result.
    public static func concurrentReduce<T: Sendable>(
        _ items: [T],
        initial: T,
        chunkSize: Int = 1024,
        combine: @Sendable (T, T) -> T
    ) -> T {
        let count = items.count
        guard count > chunkSize else {
            return items.reduce(initial, combine)
        }
        let numChunks = (count + chunkSize - 1) / chunkSize
        nonisolated(unsafe) let partials = UnsafeMutableBufferPointer<T>.allocate(capacity: numChunks)
        DispatchQueue.concurrentPerform(iterations: numChunks) { chunk in
            let lo = chunk * chunkSize
            let hi = min(lo + chunkSize, count)
            partials[chunk] = items[lo..<hi].reduce(initial, combine)
        }
        let result = Array(partials).reduce(initial, combine)
        partials.deallocate()
        return result
    }
}

// MARK: - 4. Memory & Optimization Patterns

/// Demonstrates memory-aligned buffers and performance measurement.
public enum MemoryOptimization {

    /// Page-aligned buffer for optimal I/O and SIMD access.
    public final class AlignedBuffer<T>: @unchecked Sendable {
        /// Raw pointer to the allocated memory.
        public let pointer: UnsafeMutablePointer<T>
        /// The number of elements the buffer can hold.
        public let count: Int

        /// Allocates an aligned buffer.
        ///
        /// - Parameters:
        ///   - count: Number of elements.
        ///   - alignment: Byte alignment. Defaults to the natural alignment of `T`.
        public init(count: Int, alignment: Int = MemoryLayout<T>.alignment) {
            self.count = count
            let byteCount = count * MemoryLayout<T>.stride
            self.pointer = UnsafeMutableRawPointer
                .allocate(byteCount: byteCount, alignment: alignment)
                .bindMemory(to: T.self, capacity: count)
        }

        deinit { pointer.deallocate() }

        /// Accesses the element at `index`.
        ///
        /// - Parameter index: A valid index into the buffer.
        public subscript(index: Int) -> T {
            get { pointer[index] }
            set { pointer[index] = newValue }
        }

        /// An unsafe mutable buffer pointer over the entire allocation.
        public var buffer: UnsafeMutableBufferPointer<T> {
            UnsafeMutableBufferPointer(start: pointer, count: count)
        }
    }

    /// Measures execution time of a closure in milliseconds, printing the result.
    ///
    /// - Parameters:
    ///   - label: An optional label printed with the timing. Empty string suppresses output.
    ///   - body: The closure to measure.
    /// - Returns: The value returned by `body`.
    @discardableResult
    public static func measure<R>(_ label: String = "", body: () throws -> R) rethrows -> R {
        let start = DispatchTime.now()
        let result = try body()
        let end = DispatchTime.now()
        let ns = end.uptimeNanoseconds - start.uptimeNanoseconds
        let ms = Double(ns) / 1_000_000
        if !label.isEmpty {
            print("[\(label)] \(String(format: "%.3f", ms)) ms")
        }
        return result
    }
}
