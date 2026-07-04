# AGENTS.md — SwiftTemplateUIDemo Target

A macOS demo app (`swift run SwiftTemplateUIDemo`) showcasing `SwiftTemplateUI`
in three tabs: Components (MVVM + AsyncContentView), Game (software-rendered
physics via GameCanvasView), and Metal (MTKView viewport).

Rules:

- This target is a **showcase, not a component library**. Reusable views,
  modifiers, and view models belong in `SwiftTemplateUI`; only composition and
  demo data live here.
- The non-macOS `#else` branch provides a fallback `@main` that prints a
  message — keep it, it's what lets `swift build` succeed on Linux.
- Running via SwiftPM launches a bare window without an app bundle — good
  enough for development. The path to a signed, App Store-ready app is an Xcode
  app target that imports this package; see `docs/UIGuide.md`.
- No tests cover this target and it is excluded from the coverage gate; keep it
  thin enough that that stays reasonable.
