# UI Guide

How the `SwiftTemplateUI` target works, why it's built on SwiftUI, and how to
grow it into shipping apps and games.

## Why SwiftUI

| Requirement | How SwiftUI meets it |
|---|---|
| Not bloated | First-party framework, zero dependencies added to the package |
| Plenty of control | Layered escape hatches: `Canvas` for immediate-mode drawing, `NSViewRepresentable` for any AppKit view, `MTKView` for raw Metal |
| App Store approval | Native, sandboxing-friendly, no private API risk; the mainstream path Apple's review process is built around |
| Games (2D/3D) | `SpriteView` (SpriteKit), `SceneView` (SceneKit), and `MTKView` all embed directly in SwiftUI windows |
| Longevity | The framework Apple actively invests in; AppKit is maintenance-mode by comparison |

Alternatives considered: **AppKit** alone gives maximal control but far more
code and a legacy trajectory — we use it *through* SwiftUI where needed rather
than instead of it. **Catalyst** is for porting iPad apps, not building Mac
software. **Electron/Flutter/Compose** aren't Swift, add heavyweight runtimes,
and forfeit the native look review favors.

## What's in SwiftTemplateUI

| File | Patterns |
|---|---|
| `Observation.swift` | `LoadState<Value>` phase enum; `ItemListViewModel` — `@MainActor @Observable` MVVM with an injected `@Sendable` loader |
| `Components.swift` | `CardModifier`/`.card()`, `PrimaryButtonStyle`/`.buttonStyle(.primary)`, `AsyncContentView` (renders a `LoadState`) |
| `GameCanvas.swift` | `PixelBuffer.makeCGImage()`, `BouncingBallScene` (Simulation module physics), `GameCanvasView` (TimelineView + Canvas fixed-timestep loop) |
| `MetalViewport.swift` | `NSViewRepresentable` wrapping `MTKView` — the minimal GPU frame loop |

Run the demo app (Components / Game / Metal tabs):

```bash
swift run SwiftTemplateUIDemo
```

## The MVVM contract

State flows one way: view models own state, views render it.

```swift
@MainActor @Observable
public final class ItemListViewModel {
    public private(set) var state: LoadState<[String]> = .idle
    // Loader injected → every transition testable without networking.
    public init(loadItems: @escaping @Sendable () async throws -> [String]) { ... }
}

struct MyView: View {
    @State private var viewModel = ItemListViewModel { try await api.fetchNames() }
    var body: some View {
        AsyncContentView(state: viewModel.state) { items in
            List(items, id: \.self) { Text($0) }
        }
        .task { await viewModel.load() }
    }
}
```

Testing happens at the view-model layer (`Tests/SwiftTemplateUITests/`) — see
the loaded/failed/filtering tests. View bodies stay logic-free and are excluded
from the coverage gate (`scripts/check-coverage.sh`).

## Games

Three tiers, all embedded in the same SwiftUI shell:

1. **Software rendering** (`GameCanvasView`) — the library's `GameScene` /
   `GameLoop` / `PixelBuffer` drawn via `Canvas`. Fully portable logic,
   deterministic, easiest to test. Right for prototypes and simple 2D.
2. **SpriteKit / SceneKit** — `SpriteView(scene:)` and `SceneView(scene:)` are
   one-line embeds for production 2D and scene-graph 3D. Reuse the Simulation
   module for physics-adjacent math.
3. **Metal** (`MetalViewport`) — extend the `Renderer` delegate with pipelines
   from `MetalRendering` (see `Rendering.swift`) for full-control 3D.

## Graduating to an App Store app

`swift run SwiftTemplateUIDemo` opens a bare window — right for development,
not for distribution. To ship:

1. Create an Xcode **macOS App** project and add this package as a local (or
   git) dependency; import `SwiftTemplateUI`.
2. The app target supplies what SwiftPM can't: `Info.plist`, asset catalog and
   icons, **App Sandbox** entitlement (required for the Mac App Store), code
   signing, and notarization.
3. Keep the app target thin — views, view models, and logic stay in the
   package where they're tested. The Xcode project is packaging, not code.

---

> **See also:** [RenderingGuide.md](RenderingGuide.md) · [ConcurrencyGuide.md](ConcurrencyGuide.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [TestingGuide.md](TestingGuide.md)
