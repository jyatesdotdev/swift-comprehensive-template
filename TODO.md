# TODO

Improvement backlog from the 2026-07-04 architecture/agent-usability review.
Items follow the AGENTS.md definition of done: implementation + mirrored tests
+ DocC comments + guide updates.

## Primitives (building blocks for future projects)

- [ ] **`RingBuffer<T>`** — fixed-capacity circular buffer (value type, COW).
      Pairs with `GameLoop` for frame-time history. → new Collections section
      or `Sources/SwiftTemplate/HPC/`
- [ ] **`LRUCache<Key, Value>`** — actor cache with eviction policy; upgrades
      the existing `Cache` actor. → `Sources/SwiftTemplate/Concurrency/`
- [ ] **`AsyncSemaphore` / concurrency limiter** — generalize the bounded
      concurrency logic buried in `StructuredConcurrency.throttledMap` into a
      reusable actor. → `Sources/SwiftTemplate/Concurrency/Resilience.swift`
- [ ] **Clock injection** — parameterize time-based APIs (e.g.
      `AsyncPatterns.countdown`) with `any Clock<Duration>` so tests run
      instantly. Teaching pattern for testable time.
- [ ] **`Synchronization.Mutex` example** — the modern (Swift 6) counterpart
      to the GCD `ReadWriteLock`, presented side by side old/new.
- [ ] **CLI `--json` output mode** — machine-readable output pattern for
      subcommands (most agent/tooling-friendly CLI improvement).
      → `Sources/SwiftTemplateCLI/`

## Modernization

- [ ] **Bump to swift-tools 6.0** and replace
      `.enableExperimentalFeature("StrictConcurrency")` with the Swift 6
      language mode. The toolchain floor is already Xcode 16.2 for tests.
- [ ] **Adopt typed throws** — `Config.require` → `throws(ConfigError)` etc.
      (requires the 6.0 bump above; `docs/ARCHITECTURE.md` references this).
- [ ] **Macro target** — a small `#URL("...")` compile-checked-literal macro
      demonstrating SwiftSyntax macros; the template's one big Swift 5.9+
      feature gap. Adds a macro target + SwiftSyntax dependency.
- [ ] **Parameterized-test showcase** — broaden `@Test(arguments:)` usage
      (currently only in `SwiftTemplateUITests`) and add `try #require(...)`
      examples to `docs/TestingGuide.md`.

## Games / UI

- [ ] **SpriteKit tab** — add a `SpriteView` demo to `SwiftTemplateUIDemo`
      (tier 2 of the games ladder in `docs/UIGuide.md`).
- [ ] **Metal triangle** — extend `MetalViewport.Renderer` from clear-pass to
      a textured/shaded triangle using `MetalRendering.makeComputePipeline`
      patterns.
- [ ] **Xcode app-target example** — document (or script) the App Store
      graduation path from `docs/UIGuide.md` §"Graduating" with a worked
      example.

## Infrastructure

- [ ] **Linux CI job** — `swift build && swift test` on Ubuntu to enforce the
      cross-platform rule (deprioritized 2026-07-04: Mac is the primary
      target, library code still keeps Linux guards).
- [ ] **PR template** — `.github/PULL_REQUEST_TEMPLATE.md` mirroring the
      AGENTS.md definition-of-done checklist.
- [ ] **Benchmarks** — a perf suite (ordo-one/package-benchmark or
      `ContinuousClock` sanity checks) for HPC/Simulation hot paths.
- [ ] **DocC build check in CI** — `swift package generate-documentation` to
      catch doc-comment drift; the plugin dependency already exists.

## Done (this review)

- [x] Per-directory AGENTS.md guides; CLAUDE.md symlinked to AGENTS.md
- [x] Stale-doc cleanup (TestingGuide XCTest removal, ARCHITECTURE CI section,
      README structure/toolchain)
- [x] `Shell.run` pipe-deadlock fix + regression tests
- [x] `Resilience.withTimeout` / `Resilience.retry`
- [x] Typed `APIService.fetch<T: Decodable>` + `MockHTTPClient`
- [x] `StateMachine<State, Event>`
- [x] `SwiftTemplateUI` target (MVVM, components, game canvas, Metal viewport)
      + `SwiftTemplateUIDemo` app + `docs/UIGuide.md`
- [x] `make verify`, `make coverage`, shared `scripts/check-coverage.sh`
