#if canImport(Testing)
import Testing
import Foundation
@testable import SwiftTemplate

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
        loop.step(elapsed: 1.0 / 30.0, buffer: &buf)
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

#endif
