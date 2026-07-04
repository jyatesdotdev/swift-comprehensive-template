# AGENTS.md — SwiftTemplate Library Target

Rules for all code under `Sources/SwiftTemplate/`. Read the root `/AGENTS.md`
first; the domain subdirectories (`Concurrency/`, `HPC/`, `Rendering/`,
`Simulation/`, `Systems/`) each have their own `AGENTS.md` with domain rules.

## Structure

This is a **single SPM target**. The subdirectories are organizational, not
separate modules — everything compiles into one `SwiftTemplate` library, so all
types share one namespace. Check for name collisions across the whole target
before adding a type (e.g., there is already a `Platform`, `Logger`, `Vec2`,
`Color4`, `Config`).

Top-level files hold cross-cutting patterns:

- `SwiftTemplate.swift` — version constant only. Bump `version` on releases.
- `BestPractices.swift` — protocol-oriented design (`Steppable`), copy-on-write
  (`COWBuffer`), typed errors (`Config`/`ConfigError`), property wrappers (`@Clamped`).
- `CrossPlatform.swift` — `Platform`, `PortablePath`, `PlatformLogger`,
  `FeatureFlags`, `PortableHTTP`, `ByteOrder`.
- `ThirdPartyPatterns.swift` — dependency abstraction: `HTTPClient` and `Logger`
  protocols, `AppDependencies` DI container, `APIService`.
- `SwiftTemplate.docc/` — DocC catalog. Update articles when public API changes.

## Non-Negotiable Constraints

1. **StrictConcurrency is on for this target** (`Package.swift` swiftSettings).
   Every public type should be `Sendable` (or `Sendable`-safe). If you must
   escape the checker, justify it inline — existing precedents:
   ```swift
   // nonisolated(unsafe): FileManager.default is effectively immutable singleton.
   nonisolated(unsafe) private static let fm = FileManager.default
   ```
   ```swift
   public final class ReadWriteLock<Value: Sendable>: @unchecked Sendable { ... }
   // safe because all access goes through the internal queue
   ```
2. **This target must build on Linux.** Only `Foundation` is unconditionally
   importable. Everything else is guarded:
   - `#if canImport(FoundationNetworking)` + import — required for `URLSession` on Linux
   - `#if canImport(Accelerate)` / `canImport(Metal)` / `canImport(QuartzCore)` /
     `canImport(SwiftUI)` / `canImport(CoreFoundation)` — Apple frameworks
   - `#if canImport(Darwin)` vs `#if canImport(Glibc)` — libc
   - `#if os(macOS) || os(Linux)` — `Process` (unavailable on iOS)
   When a whole API only makes sense with a framework, wrap the **entire type**
   in the `#if` block (see `AccelerateOps`, `MetalRendering`); never leave a
   public symbol that exists on one platform with a different shape on another.
3. **No force operations** (`!`, `as!`, `try!`) — SwiftLint errors.

## API Design Rules

- New utility in an existing domain → add a section to that domain's file under
  a new `// MARK: - N. Name` header, or extend an existing namespace enum.
- Namespaces: caseless `public enum`; group related statics inside it.
- All public API: `///` DocC comments with `- Parameters:` / `- Returns:` /
  `- Throws:`. Follow the density of the surrounding file — it is 100%.
- Errors: nested `public enum XError: Error` with associated values carrying
  context (paths, keys, names). Add `CustomStringConvertible` if messages are
  user-facing (see `FileSystem.FSError`).
- Prefer `precondition` for programmer errors (mismatched array lengths),
  `throws` for recoverable/environmental failures, `nil` returns for simple
  absence.
- Generic constraints must include `Sendable` when values cross concurrency
  boundaries (`@Sendable` closures, task groups).

## Adding a New Domain Module

Follow `docs/EXTENDING.md`. Summary: create `Sources/SwiftTemplate/NewDomain/
NewDomain.swift`, use MARK-numbered sections, add a mirrored test file
`Tests/SwiftTemplateTests/NewDomainTests.swift`, write `docs/NewDomainGuide.md`,
and update `docs/ARCHITECTURE.md` + the README module table. Keep files under
500 lines — split into multiple files inside the domain directory when needed.
