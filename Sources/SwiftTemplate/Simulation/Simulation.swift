// MARK: - Simulation Module
// Numerical computing, physics simulation, Core Animation

import Foundation

// MARK: - 1. Numerical Computing

/// 2D vector for simulation math.
public struct Vec2: Sendable, Equatable {
    /// The x-component.
    public var x: Double
    /// The y-component.
    public var y: Double

    /// Creates a 2D vector.
    ///
    /// - Parameters:
    ///   - x: The x-component.
    ///   - y: The y-component.
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }

    /// The zero vector.
    public static let zero = Vec2(0, 0)

    /// The Euclidean length of the vector.
    public var length: Double { (x * x + y * y).squareRoot() }

    /// A unit-length vector in the same direction, or `.zero` if length is near zero.
    public var normalized: Vec2 {
        let l = length; guard l > .ulpOfOne else { return .zero }
        return Vec2(x / l, y / l)
    }

    public static func + (a: Vec2, b: Vec2) -> Vec2 { Vec2(a.x + b.x, a.y + b.y) }
    public static func - (a: Vec2, b: Vec2) -> Vec2 { Vec2(a.x - b.x, a.y - b.y) }
    public static func * (a: Vec2, s: Double) -> Vec2 { Vec2(a.x * s, a.y * s) }
    public static func * (s: Double, a: Vec2) -> Vec2 { a * s }
}

/// Generic ODE state for numerical integration.
public protocol ODEState {
    static func + (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Double) -> Self
}

extension Double: ODEState {}
extension Vec2: ODEState {}

/// Numerical integration methods.
public enum Integrator {

    /// Euler method: `y_{n+1} = y_n + h * f(t, y_n)`.
    ///
    /// - Parameters:
    ///   - state: The current state.
    ///   - t: The current time.
    ///   - dt: The time step.
    ///   - derivative: A function returning the derivative at `(t, state)`.
    /// - Returns: The state after one Euler step.
    public static func euler<S: ODEState>(
        state: S, t: Double, dt: Double, derivative: (Double, S) -> S
    ) -> S {
        state + derivative(t, state) * dt
    }

    /// Classical 4th-order Runge-Kutta.
    ///
    /// - Parameters:
    ///   - state: The current state.
    ///   - t: The current time.
    ///   - dt: The time step.
    ///   - derivative: A function returning the derivative at `(t, state)`.
    /// - Returns: The state after one RK4 step.
    public static func rk4<S: ODEState>(
        state: S, t: Double, dt: Double, derivative: (Double, S) -> S
    ) -> S {
        let k1 = derivative(t, state)
        let k2 = derivative(t + dt * 0.5, state + k1 * (dt * 0.5))
        let k3 = derivative(t + dt * 0.5, state + k2 * (dt * 0.5))
        let k4 = derivative(t + dt, state + k3 * dt)
        return state + (k1 + k2 * 2.0 + k3 * 2.0 + k4) * (dt / 6.0)
    }

    /// Numerical integration using the trapezoidal rule.
    ///
    /// - Parameters:
    ///   - a: Lower bound of integration.
    ///   - b: Upper bound of integration.
    ///   - steps: Number of subdivisions.
    ///   - f: The function to integrate.
    /// - Returns: The approximate integral value.
    public static func trapezoid(
        from a: Double, to b: Double, steps: Int, f: (Double) -> Double
    ) -> Double {
        let h = (b - a) / Double(steps)
        var sum = (f(a) + f(b)) * 0.5
        for i in 1..<steps { sum += f(a + Double(i) * h) }
        return sum * h
    }
}

// MARK: - 2. Physics Simulation

/// Axis-aligned bounding box.
public struct AABB: Sendable {
    /// The minimum corner.
    public var min: Vec2
    /// The maximum corner.
    public var max: Vec2

    /// Creates an AABB from a center point and half-extents.
    ///
    /// - Parameters:
    ///   - center: The center of the box.
    ///   - halfSize: Half-width and half-height.
    public init(center: Vec2, halfSize: Vec2) {
        self.min = center - halfSize
        self.max = center + halfSize
    }

    /// Tests whether this box overlaps another.
    ///
    /// - Parameter other: The other bounding box.
    /// - Returns: `true` if the boxes overlap.
    public func overlaps(_ other: AABB) -> Bool {
        min.x <= other.max.x && max.x >= other.min.x &&
        min.y <= other.max.y && max.y >= other.min.y
    }
}

/// A particle with position, velocity, and mass for Verlet integration.
public struct Particle: Sendable {
    /// Current position.
    public var position: Vec2
    /// Position from the previous time step (used by Verlet integration).
    public var previousPosition: Vec2
    /// Accumulated acceleration for the current step.
    public var acceleration: Vec2
    /// Particle mass in kilograms.
    public var mass: Double

    /// Creates a particle.
    ///
    /// - Parameters:
    ///   - position: Initial position.
    ///   - velocity: Initial velocity. Defaults to `.zero`.
    ///   - mass: Particle mass. Defaults to `1.0`.
    public init(position: Vec2, velocity: Vec2 = .zero, mass: Double = 1.0) {
        self.position = position
        self.previousPosition = position - velocity * (1.0 / 60.0) // assume 60fps initial
        self.acceleration = .zero
        self.mass = mass
    }

    /// Applies a force to the particle (`F = ma → a = F/m`).
    ///
    /// - Parameter force: The force vector to apply.
    public mutating func applyForce(_ force: Vec2) {
        acceleration = acceleration + force * (1.0 / mass)
    }

    /// Advances the particle using Störmer-Verlet integration.
    ///
    /// - Parameter dt: The time step in seconds.
    public mutating func integrate(dt: Double) {
        let newPos = position * 2.0 - previousPosition + acceleration * (dt * dt)
        previousPosition = position
        position = newPos
        acceleration = .zero
    }
}

/// Simple particle system with gravity and ground-plane collision.
public struct ParticleSystem: Sendable {
    /// The particles in the system.
    public var particles: [Particle]
    /// Gravitational acceleration applied each step.
    public var gravity: Vec2
    /// The y-coordinate of the ground plane.
    public var groundY: Double

    /// Creates a particle system.
    ///
    /// - Parameters:
    ///   - gravity: Gravitational acceleration. Defaults to `(0, -9.81)`.
    ///   - groundY: Ground plane y-coordinate. Defaults to `0`.
    public init(gravity: Vec2 = Vec2(0, -9.81), groundY: Double = 0) {
        self.particles = []
        self.gravity = gravity
        self.groundY = groundY
    }

    /// Adds a particle to the system.
    ///
    /// - Parameter p: The particle to add.
    public mutating func addParticle(_ p: Particle) {
        particles.append(p)
    }

    /// Advances the simulation by `dt` seconds.
    ///
    /// - Parameter dt: The time step in seconds.
    public mutating func step(dt: Double) {
        for i in particles.indices {
            particles[i].applyForce(gravity * particles[i].mass)
            particles[i].integrate(dt: dt)
            // Ground collision: reflect below ground
            if particles[i].position.y < groundY {
                particles[i].position.y = groundY
                particles[i].previousPosition.y = groundY + (groundY - particles[i].previousPosition.y) * 0.5
            }
        }
    }
}

/// Spring connecting two particle indices with damping.
public struct Spring: Sendable {
    /// Index of the first particle.
    public let a: Int
    /// Index of the second particle.
    public let b: Int
    /// The natural length of the spring.
    public let restLength: Double
    /// Spring stiffness coefficient.
    public let stiffness: Double

    /// Creates a spring constraint between two particles.
    ///
    /// - Parameters:
    ///   - a: Index of the first particle.
    ///   - b: Index of the second particle.
    ///   - restLength: The natural length of the spring.
    ///   - stiffness: Spring stiffness. Defaults to `100.0`.
    public init(a: Int, b: Int, restLength: Double, stiffness: Double = 100.0) {
        self.a = a; self.b = b
        self.restLength = restLength; self.stiffness = stiffness
    }

    /// Applies position-based constraint relaxation to the given particles.
    ///
    /// - Parameter particles: The particle array (modified in-place).
    public func apply(to particles: inout [Particle]) {
        let delta = particles[b].position - particles[a].position
        let dist = delta.length
        guard dist > .ulpOfOne else { return }
        let diff = (dist - restLength) / dist * 0.5
        let offset = delta * diff
        particles[a].position = particles[a].position + offset
        particles[b].position = particles[b].position - offset
    }
}

// MARK: - 3. Core Animation Patterns

#if canImport(QuartzCore)
import QuartzCore

/// Demonstrates Core Animation timing and layer animation patterns.
public enum CoreAnimationPatterns {

    /// Creates a basic position animation.
    ///
    /// - Parameters:
    ///   - from: The starting position.
    ///   - to: The ending position.
    ///   - duration: Animation duration in seconds. Defaults to `0.3`.
    /// - Returns: A configured `CABasicAnimation`.
    public static func positionAnimation(
        from: CGPoint, to: CGPoint, duration: CFTimeInterval = 0.3
    ) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "position")
        anim.fromValue = NSValue(point: from)
        anim.toValue = NSValue(point: to)
        anim.duration = duration
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return anim
    }

    /// Creates a keyframe animation along a path.
    ///
    /// - Parameters:
    ///   - path: The `CGPath` to animate along.
    ///   - duration: Animation duration in seconds. Defaults to `1.0`.
    /// - Returns: A configured `CAKeyframeAnimation`.
    public static func pathAnimation(
        path: CGPath, duration: CFTimeInterval = 1.0
    ) -> CAKeyframeAnimation {
        let anim = CAKeyframeAnimation(keyPath: "position")
        anim.path = path
        anim.duration = duration
        anim.calculationMode = .paced
        return anim
    }

    /// Creates a spring-like animation using `CASpringAnimation`.
    ///
    /// - Parameters:
    ///   - keyPath: The layer property to animate.
    ///   - value: The target value.
    ///   - damping: Damping coefficient. Defaults to `10`.
    ///   - stiffness: Spring stiffness. Defaults to `100`.
    ///   - mass: Simulated mass. Defaults to `1`.
    /// - Returns: A configured `CASpringAnimation`.
    public static func springAnimation(
        keyPath: String, to value: Any,
        damping: CGFloat = 10, stiffness: CGFloat = 100, mass: CGFloat = 1
    ) -> CASpringAnimation {
        let anim = CASpringAnimation(keyPath: keyPath)
        anim.toValue = value
        anim.damping = damping
        anim.stiffness = stiffness
        anim.mass = mass
        anim.duration = anim.settlingDuration
        return anim
    }

    /// Creates a custom timing function using cubic Bézier control points.
    ///
    /// - Parameters:
    ///   - c1x: X of the first control point.
    ///   - c1y: Y of the first control point.
    ///   - c2x: X of the second control point.
    ///   - c2y: Y of the second control point.
    /// - Returns: A `CAMediaTimingFunction`.
    public static func customTimingFunction(
        c1x: Float, c1y: Float, c2x: Float, c2y: Float
    ) -> CAMediaTimingFunction {
        CAMediaTimingFunction(controlPoints: c1x, c1y, c2x, c2y)
    }
}
#endif
