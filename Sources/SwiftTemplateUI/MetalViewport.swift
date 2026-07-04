// MARK: - Metal Viewport
// Minimal MTKView embedded in SwiftUI via NSViewRepresentable (macOS only).

#if os(macOS) && canImport(MetalKit) && canImport(SwiftUI)
import MetalKit
import SwiftUI

/// A SwiftUI-embedded `MTKView` running a minimal render pass with an
/// animated clear color — the smallest possible "GPU is alive" loop.
///
/// This is the escape hatch pattern for real-time 3D: SwiftUI owns the window
/// and chrome, `MTKViewDelegate` owns the frame loop, and everything in
/// ``SwiftTemplate/MetalRendering`` is available for the actual GPU work.
public struct MetalViewport: NSViewRepresentable {
    /// Creates a Metal viewport.
    public init() {}

    /// Creates the frame-loop delegate.
    public func makeCoordinator() -> Renderer { Renderer() }

    /// Builds and configures the underlying `MTKView`.
    ///
    /// - Parameter context: The representable context carrying the coordinator.
    public func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.preferredFramesPerSecond = 60
        view.delegate = context.coordinator
        return view
    }

    /// No SwiftUI-driven state to push; the delegate animates itself.
    public func updateNSView(_ nsView: MTKView, context: Context) {}

    /// Minimal `MTKViewDelegate`: encodes one empty render pass per frame with
    /// a time-varying clear color.
    public final class Renderer: NSObject, MTKViewDelegate {
        private var commandQueue: MTLCommandQueue?
        private var time: Double = 0

        /// Required by the protocol; nothing to do for a clear-only pass.
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        /// Encodes and presents one frame.
        ///
        /// - Parameter view: The view requesting the frame.
        public func draw(in view: MTKView) {
            guard let device = view.device else { return }
            if commandQueue == nil { commandQueue = device.makeCommandQueue() }
            guard let queue = commandQueue,
                  let descriptor = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable,
                  let commandBuffer = queue.makeCommandBuffer() else { return }

            time += 1.0 / Double(max(view.preferredFramesPerSecond, 1))
            let pulse = 0.5 + 0.5 * sin(time)
            descriptor.colorAttachments[0].clearColor = MTLClearColor(
                red: 0.10, green: 0.10 + 0.25 * pulse, blue: 0.35, alpha: 1
            )

            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
#endif
