// MARK: - Game Canvas
// Bridges the library's software renderer (PixelBuffer / GameScene / GameLoop)
// into SwiftUI via TimelineView + Canvas.

#if canImport(SwiftUI) && canImport(CoreGraphics)
import CoreGraphics
import SwiftTemplate
import SwiftUI

// MARK: - 1. PixelBuffer → CGImage

extension PixelBuffer {
    /// Converts the buffer to an RGBA8 `CGImage` for display.
    ///
    /// - Returns: The image, or `nil` if a graphics resource could not be created.
    public func makeCGImage() -> CGImage? {
        var bytes = [UInt8]()
        bytes.reserveCapacity(width * height * 4)
        for pixel in pixels {
            bytes.append(UInt8(min(max(pixel.r, 0), 1) * 255))
            bytes.append(UInt8(min(max(pixel.g, 0), 1) * 255))
            bytes.append(UInt8(min(max(pixel.b, 0), 1) * 255))
            bytes.append(UInt8(min(max(pixel.a, 0), 1) * 255))
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}

// MARK: - 2. Demo Scene

/// Particles under gravity, rendered as bright squares — demonstrates driving
/// the Simulation and Rendering modules from a UI.
public final class BouncingBallScene: GameScene {
    private var system: ParticleSystem
    /// World-space extents mapped onto the pixel buffer.
    private let worldWidth: Double = 10
    private let worldHeight: Double = 7.5

    /// Creates the scene with a spread of launched particles.
    ///
    /// - Parameter particleCount: How many particles to simulate.
    public init(particleCount: Int = 5) {
        system = ParticleSystem()
        for i in 0..<max(1, particleCount) {
            let x = 1.0 + Double(i) * (worldWidth - 2) / Double(max(1, particleCount - 1))
            let particle = Particle(
                position: Vec2(x, 1.0),
                velocity: Vec2(0, 4.0 + Double(i % 3))
            )
            system.addParticle(particle)
        }
    }

    /// Advances the physics simulation.
    ///
    /// - Parameter dt: The fixed time step in seconds.
    public func update(dt: Double) {
        system.step(dt: dt)
    }

    /// Draws the particles into the buffer.
    ///
    /// - Parameter buffer: The target pixel buffer.
    public func render(into buffer: inout PixelBuffer) {
        buffer.fillRect(x: 0, y: 0, w: buffer.width, h: buffer.height, color: .black)
        let scaleX = Double(buffer.width) / worldWidth
        let scaleY = Double(buffer.height) / worldHeight
        for particle in system.particles {
            let px = Int(particle.position.x * scaleX)
            // World y is up; pixel y is down.
            let py = buffer.height - 1 - Int(particle.position.y * scaleY)
            buffer.fillRect(x: px - 2, y: py - 2, w: 4, h: 4, color: Color4(r: 1, g: 0.85, b: 0.2))
        }
    }
}

// MARK: - 3. SwiftUI Canvas View

/// Per-frame driver holding the loop state across view updates.
///
/// Confined to the main thread by SwiftUI's render loop; `@unchecked Sendable`
/// only to satisfy `@State` storage under strict concurrency.
final class GameDriver: @unchecked Sendable {
    private let loop: GameLoop
    private let scene: GameScene // GameLoop holds the scene weakly; retain it here.
    private var buffer: PixelBuffer
    private var lastDate: Date?

    init(scene: GameScene, width: Int, height: Int) {
        self.scene = scene
        self.loop = GameLoop(scene: scene)
        self.buffer = PixelBuffer(width: width, height: height)
    }

    func frame(at date: Date) -> CGImage? {
        let elapsed = lastDate.map { date.timeIntervalSince($0) } ?? 0
        lastDate = date
        // Clamp so a paused window doesn't trigger a catch-up spiral.
        loop.step(elapsed: min(max(elapsed, 0), 0.25), buffer: &buffer)
        return buffer.makeCGImage()
    }
}

/// Runs a ``SwiftTemplate/GameScene`` at a fixed timestep and displays it,
/// scaled to fit, in a SwiftUI `Canvas` driven by `TimelineView(.animation)`.
public struct GameCanvasView: View {
    @State private var driver: GameDriver

    /// Creates a game canvas.
    ///
    /// - Parameters:
    ///   - scene: The scene to run. Retained for the lifetime of the view.
    ///   - width: Pixel-buffer width. Defaults to `160`.
    ///   - height: Pixel-buffer height. Defaults to `120`.
    public init(scene: GameScene, width: Int = 160, height: Int = 120) {
        _driver = State(initialValue: GameDriver(scene: scene, width: width, height: height))
    }

    /// The animating canvas.
    public var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard let image = driver.frame(at: timeline.date) else { return }
                context.draw(
                    Image(decorative: image, scale: 1),
                    in: CGRect(origin: .zero, size: size)
                )
            }
        }
    }
}
#endif
