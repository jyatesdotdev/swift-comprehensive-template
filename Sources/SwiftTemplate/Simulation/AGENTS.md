# AGENTS.md — Simulation Module

`Simulation.swift` covers numerical computing (`Vec2`, `ODEState`,
`Integrator`), physics (`AABB`, `Particle`, `ParticleSystem`, `Spring`), and
Core Animation (`CoreAnimationPatterns`, Apple-only).

## Established patterns to reuse

- **`ODEState` protocol** requires only `+` and `* Double` — that is what makes
  `Integrator.euler`/`rk4` generic over `Double`, `Vec2`, or any state you
  conform. To integrate a new state type, conform it to `ODEState`; do not write
  a bespoke integrator.
- **Integration methods are pure functions**: `(state, t, dt, derivative) →
  state`. No stored state, no side effects. Keep new solvers in that shape.
- **Verlet particles**: `Particle` stores `previousPosition` instead of
  velocity; forces accumulate into `acceleration` and reset each `integrate`.
  If you need velocity, derive it as `(position - previousPosition) / dt`.
- **Constraint relaxation**: `Spring.apply` nudges both endpoints half the
  error. Position-based dynamics style — iterate constraints for stiffness
  rather than raising a gain until it explodes.
- Everything is a `Sendable` **struct**. Simulation state stays value-typed so
  callers get snapshotting and thread-safety for free.

## Constraints & pitfalls

- **Near-zero guards use `.ulpOfOne`** before dividing by a length
  (`Vec2.normalized`, `Spring.apply`). Never divide by an unchecked magnitude.
- The `// swiftlint:disable:this shorthand_operator` disables on
  `a = a + offset` lines exist because SwiftLint wants `+=` where the mutating
  form isn't defined for that expression shape. Prefer defining/using the
  compound operator; copy the existing inline-disable style only when that
  isn't reasonable.
- `CoreAnimationPatterns` must stay entirely inside `#if canImport(QuartzCore)`.
  Physics and math must stay **outside** it — they are portable and tested on
  Linux.
- Physics defaults are physical: gravity `(0, -9.81)`, y-up coordinates, masses
  in kg, dt in seconds. Keep new APIs in SI units and document deviations.

## Testing

`Tests/SwiftTemplateTests/SimulationTests.swift`. Verify integrators against
closed-form solutions with explicit tolerances (e.g. RK4 on `y' = y` vs `e^t`),
not against magic constants. Simulation must be deterministic — no randomness
in library code.
