#if canImport(Testing)
import Testing
import Foundation
@testable import SwiftTemplate

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
        let result = Integrator.euler(state: 0.0, t: 0, dt: 1.0) { _, _ in 2.0 }
        #expect(abs(result - 2.0) < 1e-12)
    }

    @Test func rk4Accuracy() {
        var y = 1.0
        let steps = 100; let dt = 1.0 / Double(steps)
        for i in 0..<steps {
            y = Integrator.rk4(state: y, t: Double(i) * dt, dt: dt) { _, s in s }
        }
        #expect(abs(y - 2.718281828459045) < 1e-9, "RK4 should approximate e")
    }

    @Test func trapezoidIntegration() {
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
        #expect(p.acceleration.x == 5.0)
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
        #expect(particles[0].position == Vec2(0, 0))
    }
}

#elseif canImport(XCTest)
import XCTest
@testable import SwiftTemplate

final class SimulationXCTests: XCTestCase {
    func testVec2Arithmetic() {
        let a = Vec2(3, 4), b = Vec2(1, 2)
        XCTAssertEqual(a + b, Vec2(4, 6))
        XCTAssertEqual(a - b, Vec2(2, 2))
        XCTAssertEqual(a * 2.0, Vec2(6, 8))
        XCTAssertEqual(2.0 * a, Vec2(6, 8))
    }
    func testVec2Length() {
        XCTAssertEqual(Vec2(3, 4).length, 5.0, accuracy: 1e-12)
        XCTAssertEqual(Vec2.zero.length, 0.0)
    }
    func testVec2Normalized() {
        let n = Vec2(3, 4).normalized
        XCTAssertEqual(n.length, 1.0, accuracy: 1e-12)
        XCTAssertEqual(Vec2.zero.normalized, .zero)
    }
    func testVec2PlusEquals() {
        var v = Vec2(1, 2); v += Vec2(3, 4)
        XCTAssertEqual(v, Vec2(4, 6))
    }
    func testEuler() {
        let r = Integrator.euler(state: 0.0, t: 0, dt: 1.0) { _, _ in 2.0 }
        XCTAssertEqual(r, 2.0, accuracy: 1e-12)
    }
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
        let c = AABB(center: Vec2(3, 0), halfSize: Vec2(1, 1))
        XCTAssertTrue(a.overlaps(b))
        XCTAssertFalse(a.overlaps(c))
    }
    func testParticle() {
        var p = Particle(position: Vec2(0, 0), mass: 2.0)
        p.applyForce(Vec2(10, 0))
        XCTAssertEqual(p.acceleration.x, 5.0)
        p.integrate(dt: 1.0/60.0)
        XCTAssertGreaterThan(p.position.x, 0)
    }
    func testSpring() {
        var particles = [Particle(position: Vec2(0, 0)), Particle(position: Vec2(3, 0))]
        let spring = Spring(a: 0, b: 1, restLength: 2.0)
        for _ in 0..<100 { spring.apply(to: &particles) }
        let dist = (particles[1].position - particles[0].position).length
        XCTAssertEqual(dist, 2.0, accuracy: 1e-6)
    }
    func testParticleSystem() {
        var system = ParticleSystem(gravity: Vec2(0, -10), groundY: 0)
        system.addParticle(Particle(position: Vec2(0, 5)))
        for _ in 0..<600 { system.step(dt: 1.0/60.0) }
        XCTAssertGreaterThanOrEqual(system.particles[0].position.y, 0.0)
    }
}
#endif
