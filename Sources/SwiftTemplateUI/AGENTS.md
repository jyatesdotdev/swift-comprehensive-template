# AGENTS.md — SwiftTemplateUI Target

SwiftUI building blocks for macOS apps (library target, depends on
`SwiftTemplate`). **This target is Apple-only by design** — every file is
wrapped in `#if canImport(SwiftUI)` so the package still builds on Linux, but
no Linux functionality is expected here. UI logic must still be Sendable-clean
(StrictConcurrency is on).

## Layout

- `Observation.swift` — `LoadState<Value>` (idle/loading/loaded/failed) and
  `ItemListViewModel`, the canonical `@MainActor @Observable` MVVM example with
  an injected `@Sendable` async loader.
- `Components.swift` — `CardModifier` + `.card()`, `PrimaryButtonStyle` +
  `.buttonStyle(.primary)`, and `AsyncContentView` which renders a `LoadState`.
- `GameCanvas.swift` — `PixelBuffer.makeCGImage()`, `BouncingBallScene`
  (drives the Simulation module), and `GameCanvasView` (TimelineView + Canvas
  fixed-timestep loop). This is the software-rendering path for 2D.
- `MetalViewport.swift` — `NSViewRepresentable` wrapping `MTKView` with a
  minimal delegate render loop. This is the escape hatch / starting point for
  real-time 3D. macOS-only (`#if os(macOS) && canImport(MetalKit)`).

## Architecture rules

1. **Logic lives in view models, views stay declarative.** Anything worth
   testing goes in an `@Observable` class or a plain function — view `body`
   code is exempt from the coverage gate precisely because it should contain
   nothing testable.
2. **View models are `@MainActor @Observable final class`** with dependencies
   injected as `@Sendable` closures or protocol values (see the root DI
   patterns in `ThirdPartyPatterns.swift`). Mark stored closures
   `@ObservationIgnored`.
3. **Views render state, they don't own workflows.** Async work starts in
   `.task {}` or user actions calling `await viewModel.something()`; views
   never create Tasks that outlive them.
4. **Drop down deliberately**: Canvas/TimelineView for immediate-mode 2D,
   `NSViewRepresentable` for AppKit/MetalKit interop. Prefer the highest layer
   that can do the job; when you must drop down, keep the wrapper thin like
   `MetalViewport`.
5. Simulation/rendering logic belongs in the core `SwiftTemplate` modules —
   this target only *bridges* it to SwiftUI (see how `BouncingBallScene`
   composes `ParticleSystem` + `PixelBuffer` rather than reimplementing them).

## Testing

Tests live in `Tests/SwiftTemplateUITests/`. Test view models (`@MainActor`
suites), `LoadState` logic, the pixel bridge, and scene update/render behavior.
View bodies and the MTKView delegate are not unit-testable and are excluded
from the coverage gate (see `scripts/check-coverage.sh`) — do not let that
become an excuse to bury logic in views.
