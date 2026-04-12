// MARK: - Rendering Module
// Metal, Core Graphics, SwiftUI graphics, game development patterns

import Foundation

// MARK: - 1. Metal Rendering Pipeline

#if canImport(Metal)
import Metal
import simd

/// Demonstrates Metal GPU setup, compute pipelines, and buffer management.
public enum MetalRendering {

    /// Wraps a Metal device and command queue for GPU work.
    public final class GPUContext: @unchecked Sendable {
        /// The Metal device used for GPU operations.
        public let device: MTLDevice
        /// The command queue for submitting work to the GPU.
        public let commandQueue: MTLCommandQueue

        /// Creates a GPU context using the system default Metal device.
        ///
        /// - Returns: `nil` if no Metal device is available.
        public init?() {
            guard let device = MTLCreateSystemDefaultDevice(),
                  let queue = device.makeCommandQueue() else { return nil }
            self.device = device
            self.commandQueue = queue
        }
    }

    /// Creates a compute pipeline from Metal Shading Language source.
    ///
    /// - Parameters:
    ///   - context: The GPU context to use.
    ///   - source: MSL source code.
    ///   - name: The kernel function name.
    /// - Returns: A compiled compute pipeline state.
    /// - Throws: ``MetalError/functionNotFound(_:)`` or Metal compilation errors.
    public static func makeComputePipeline(
        context: GPUContext,
        source: String,
        function name: String
    ) throws -> MTLComputePipelineState {
        let library = try context.device.makeLibrary(source: source, options: nil)
        guard let function = library.makeFunction(name: name) else {
            throw MetalError.functionNotFound(name)
        }
        return try context.device.makeComputePipelineState(function: function)
    }

    /// Runs a simple compute shader that doubles each element in a Float array.
    ///
    /// - Parameters:
    ///   - input: The array of floats to double.
    ///   - context: The GPU context to use.
    /// - Returns: An array where each element is `input[i] * 2`.
    /// - Throws: ``MetalError`` on resource creation or pipeline failure.
    public static func doubleArray(_ input: [Float], context: GPUContext) throws -> [Float] {
        let source = """
        #include <metal_stdlib>
        using namespace metal;
        kernel void doubleValues(
            device float *data [[buffer(0)]],
            uint id [[thread_position_in_grid]]
        ) { data[id] *= 2.0; }
        """
        let pipeline = try makeComputePipeline(context: context, source: source, function: "doubleValues")
        let count = input.count
        let byteCount = count * MemoryLayout<Float>.stride

        guard let buffer = context.device.makeBuffer(bytes: input, length: byteCount, options: .storageModeShared),
              let cmdBuffer = context.commandQueue.makeCommandBuffer(),
              let encoder = cmdBuffer.makeComputeCommandEncoder() else {
            throw MetalError.resourceCreationFailed
        }

        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(buffer, offset: 0, index: 0)

        let threadWidth = pipeline.threadExecutionWidth
        let threadsPerGrid = MTLSize(width: count, height: 1, depth: 1)
        let threadsPerGroup = MTLSize(width: min(threadWidth, count), height: 1, depth: 1)
        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        encoder.endEncoding()

        cmdBuffer.commit()
        cmdBuffer.waitUntilCompleted()

        return Array(UnsafeBufferPointer(start: buffer.contents().assumingMemoryBound(to: Float.self), count: count))
    }

    /// Errors from Metal operations.
    public enum MetalError: Error {
        /// The named kernel function was not found in the library.
        case functionNotFound(String)
        /// A Metal resource (buffer, command buffer, or encoder) could not be created.
        case resourceCreationFailed
    }
}
#endif

// MARK: - 2. Core Graphics

#if canImport(CoreGraphics)
import CoreGraphics

/// Demonstrates Core Graphics drawing: contexts, paths, gradients, images.
public enum CoreGraphicsRendering {

    /// Creates an RGBA bitmap context of the given size.
    ///
    /// - Parameters:
    ///   - width: Width in pixels.
    ///   - height: Height in pixels.
    /// - Returns: A bitmap context, or `nil` on failure.
    public static func makeContext(width: Int, height: Int) -> CGContext? {
        CGContext(
            data: nil,
            width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }

    /// Draws a filled rounded rectangle and returns the resulting image.
    ///
    /// - Parameters:
    ///   - width: Image width in pixels.
    ///   - height: Image height in pixels.
    ///   - cornerRadius: The corner radius.
    ///   - fillColor: The fill color.
    /// - Returns: A `CGImage`, or `nil` on failure.
    public static func drawRoundedRect(
        width: Int, height: Int,
        cornerRadius: CGFloat,
        fillColor: CGColor
    ) -> CGImage? {
        guard let ctx = makeContext(width: width, height: height) else { return nil }
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(fillColor)
        ctx.fillPath()
        return ctx.makeImage()
    }

    /// Draws a linear gradient between two colors.
    ///
    /// - Parameters:
    ///   - width: Image width in pixels.
    ///   - height: Image height in pixels.
    ///   - startColor: The gradient start color.
    ///   - endColor: The gradient end color.
    /// - Returns: A `CGImage`, or `nil` on failure.
    public static func drawGradient(
        width: Int, height: Int,
        from startColor: CGColor,
        to endColor: CGColor
    ) -> CGImage? {
        guard let ctx = makeContext(width: width, height: height),
              let gradient = CGGradient(
                  colorsSpace: CGColorSpaceCreateDeviceRGB(),
                  colors: [startColor, endColor] as CFArray,
                  locations: [0, 1]
              ) else { return nil }
        ctx.drawLinearGradient(
            gradient,
            start: .zero,
            end: CGPoint(x: width, y: height),
            options: []
        )
        return ctx.makeImage()
    }

    /// Composites a checkerboard pattern — demonstrates clipping and transforms.
    ///
    /// - Parameters:
    ///   - width: Image width in pixels.
    ///   - height: Image height in pixels.
    ///   - tileSize: Size of each tile in pixels.
    ///   - color1: First tile color.
    ///   - color2: Second tile color.
    /// - Returns: A `CGImage`, or `nil` on failure.
    public static func drawCheckerboard(
        width: Int, height: Int,
        tileSize: Int,
        color1: CGColor, color2: CGColor
    ) -> CGImage? {
        guard let ctx = makeContext(width: width, height: height) else { return nil }
        for row in 0..<(height / tileSize) {
            for col in 0..<(width / tileSize) {
                let color = (row + col).isMultiple(of: 2) ? color1 : color2
                ctx.setFillColor(color)
                ctx.fill(CGRect(x: col * tileSize, y: row * tileSize, width: tileSize, height: tileSize))
            }
        }
        return ctx.makeImage()
    }
}
#endif

// MARK: - 3. SwiftUI Graphics (Shape Protocol)

#if canImport(SwiftUI)
import SwiftUI

/// Custom SwiftUI Shape: a regular polygon with N sides.
@available(macOS 14.0, iOS 17.0, *)
public struct RegularPolygon: Shape {
    /// The number of sides (minimum 3).
    public var sides: Int

    /// Creates a regular polygon shape.
    ///
    /// - Parameter sides: Number of sides (clamped to a minimum of 3).
    public init(sides: Int) { self.sides = max(3, sides) }

    /// Generates the polygon path within the given rectangle.
    ///
    /// - Parameter rect: The bounding rectangle.
    /// - Returns: The polygon path.
    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<sides {
            let angle = (Double(i) / Double(sides)) * 2 * .pi - .pi / 2
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// Star shape with configurable points and inner radius ratio.
@available(macOS 14.0, iOS 17.0, *)
public struct Star: Shape {
    /// The number of star points (minimum 2).
    public var points: Int
    /// Ratio of inner to outer radius (0–1).
    public var innerRatio: CGFloat

    /// Creates a star shape.
    ///
    /// - Parameters:
    ///   - points: Number of star points. Defaults to `5`.
    ///   - innerRatio: Inner-to-outer radius ratio. Defaults to `0.4`.
    public init(points: Int = 5, innerRatio: CGFloat = 0.4) {
        self.points = max(2, points)
        self.innerRatio = innerRatio
    }

    /// Generates the star path within the given rectangle.
    ///
    /// - Parameter rect: The bounding rectangle.
    /// - Returns: The star path.
    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var path = Path()
        for i in 0..<(points * 2) {
            let angle = (Double(i) / Double(points * 2)) * 2 * .pi - .pi / 2
            let r = i.isMultiple(of: 2) ? outer : inner
            let pt = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}
#endif

// MARK: - 4. Platform-Agnostic Rendering Abstractions

/// A simple color representation that works on all platforms.
public struct Color4: Sendable, Equatable {
    /// Red component (0–1).
    public var r: Float
    /// Green component (0–1).
    public var g: Float
    /// Blue component (0–1).
    public var b: Float
    /// Alpha component (0–1).
    public var a: Float

    /// Creates a color from RGBA components.
    ///
    /// - Parameters:
    ///   - r: Red (0–1).
    ///   - g: Green (0–1).
    ///   - b: Blue (0–1).
    ///   - a: Alpha (0–1). Defaults to `1`.
    public init(r: Float, g: Float, b: Float, a: Float = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    /// Opaque white.
    public static let white = Color4(r: 1, g: 1, b: 1)
    /// Opaque black.
    public static let black = Color4(r: 0, g: 0, b: 0)
    /// Fully transparent.
    public static let clear = Color4(r: 0, g: 0, b: 0, a: 0)
}

/// A software pixel buffer for cross-platform rendering.
public struct PixelBuffer: Sendable {
    /// Buffer width in pixels.
    public let width: Int
    /// Buffer height in pixels.
    public let height: Int
    /// The flat array of pixel colors (row-major).
    public private(set) var pixels: [Color4]

    /// Creates a pixel buffer filled with a uniform color.
    ///
    /// - Parameters:
    ///   - width: Width in pixels.
    ///   - height: Height in pixels.
    ///   - fill: The initial fill color. Defaults to ``Color4/clear``.
    public init(width: Int, height: Int, fill: Color4 = .clear) {
        self.width = width
        self.height = height
        self.pixels = Array(repeating: fill, count: width * height)
    }

    /// Accesses the pixel at `(x, y)`.
    ///
    /// - Parameters:
    ///   - x: Column index.
    ///   - y: Row index.
    public subscript(x: Int, y: Int) -> Color4 {
        get { pixels[y * width + x] }
        set { pixels[y * width + x] = newValue }
    }

    /// Fills a rectangular region with a color.
    ///
    /// - Parameters:
    ///   - x: Left edge.
    ///   - y: Top edge.
    ///   - w: Width.
    ///   - h: Height.
    ///   - color: The fill color.
    public mutating func fillRect(x: Int, y: Int, w: Int, h: Int, color: Color4) {
        for row in max(0, y)..<min(height, y + h) {
            for col in max(0, x)..<min(width, x + w) {
                self[col, row] = color
            }
        }
    }

    /// Draws a line using Bresenham's algorithm.
    ///
    /// - Parameters:
    ///   - p0: Start point `(x, y)`.
    ///   - p1: End point `(x, y)`.
    ///   - color: The line color.
    public mutating func drawLine(from p0: (Int, Int), to p1: (Int, Int), color: Color4) {
        var (x0, y0) = p0
        let (x1, y1) = p1
        let dx = abs(x1 - x0), dy = -abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1
        var err = dx + dy
        while true {
            if x0 >= 0 && x0 < width && y0 >= 0 && y0 < height { self[x0, y0] = color }
            if x0 == x1 && y0 == y1 { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x0 += sx }
            if e2 <= dx { err += dx; y0 += sy }
        }
    }
}

// MARK: - 5. Game Loop Pattern

/// A fixed-timestep game loop abstraction.
public protocol GameScene: AnyObject {
    /// Updates game state by one tick.
    ///
    /// - Parameter dt: The fixed time step in seconds.
    func update(dt: Double)

    /// Renders the current state into a pixel buffer.
    ///
    /// - Parameter buffer: The target pixel buffer.
    func render(into buffer: inout PixelBuffer)
}

/// Drives a GameScene at a fixed timestep, accumulating time between frames.
public final class GameLoop: @unchecked Sendable {
    /// The fixed time step in seconds.
    public let tickRate: Double
    private var accumulator: Double = 0
    private weak var scene: GameScene?
    private var running = false

    /// Creates a game loop for the given scene.
    ///
    /// - Parameters:
    ///   - tickRate: Fixed time step in seconds. Defaults to `1/60`.
    ///   - scene: The scene to drive.
    public init(tickRate: Double = 1.0 / 60.0, scene: GameScene) {
        self.tickRate = tickRate
        self.scene = scene
    }

    /// Advances the simulation by `elapsed` seconds (call from display link / timer).
    ///
    /// - Parameters:
    ///   - elapsed: Wall-clock time since the last call.
    ///   - buffer: The pixel buffer to render into.
    public func step(elapsed: Double, buffer: inout PixelBuffer) {
        accumulator += elapsed
        while accumulator >= tickRate {
            scene?.update(dt: tickRate)
            accumulator -= tickRate
        }
        scene?.render(into: &buffer)
    }
}
