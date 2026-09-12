# AGENTS.md — Systems Module

`Systems.swift` covers OS-level programming in seven sections: `FileSystem`,
`SystemEnvironment`, `Shell` (process launching), `StreamIO`, `UnsafeMemory`,
`CFBridging`, and `Signals`. This module has the most platform guards and the
most safety-critical code in the repo — read the constraints below before editing.

## Platform guards in force

- `Shell` (uses `Process`): `#if os(macOS) || os(Linux)` — **not** available on
  iOS/tvOS/watchOS, and `canImport(Foundation)` is not a sufficient check.
- `CFBridging`: `#if canImport(CoreFoundation)`.
- `Signals`: `#if canImport(Glibc) || canImport(Darwin)` with a nested
  Darwin/Glibc import switch.
- Everything else is portable Foundation and must stay that way.

## Established patterns to reuse

- **Typed, contextual errors**: `FileSystem.FSError` carries the path in every
  case, wraps underlying errors (`ioError(String, underlying: Error)`), and is
  `CustomStringConvertible`. New failure modes extend this enum.
- **Read, then classify**: `readData` / `readChunked` open or read first and map
  failure onto ``FileSystem/FSError`` (not exists-then-act).
- **Atomic writes**: write to a `UUID`-named temp file in the *same directory*,
  then `replaceItemAt` if the dest exists or `moveItem` if not. Never unlink
  the destination first. Same-directory matters — cross-volume moves aren't atomic.
- **Resource cleanup with `defer`**: `defer { handle.closeFile() }` immediately
  after acquiring; `defer { ptr.deallocate() }` immediately after `allocate`.
- **Scoped unsafe access**: `UnsafeMemory.withManualBuffer` owns
  allocate/deallocate and passes the buffer to a closure — never return a raw
  pointer whose lifetime the caller must guess. Follow this shape for any new
  pointer utility.
- **`Shell.run` never throws** — launch failure is encoded as
  `RunResult(exitCode: -1, stderr: ...)`, so callers handle exactly one shape.
- The `nonisolated(unsafe) private static let fm = FileManager.default` escape
  is justified by an inline comment. Same rule for any new escape: prove it.

## Pitfalls

- **Signal handlers** (`Signals.trap`) are `@convention(c)`: they cannot
  capture context, and only async-signal-safe operations are allowed inside
  (no allocation, no `print` in real code — the CLI demo uses `_Exit`).
- `Shell.sh` runs through `/bin/sh -c` — never interpolate untrusted input into
  the expression string; prefer `Shell.run` with an argument array.
- `CFBridging.scheduleTimer` manually balances `Unmanaged.passRetained` with a
  `release` callback in the timer context. If you touch it, keep the
  retain/release pairing intact or it leaks/crashes.
- Reading whole files (`readData`) is for small files; streaming goes through
  `StreamIO.readChunked` with its 64 KB default.

## Testing

`Tests/SwiftTemplateTests/SystemsTests.swift`. File tests operate under
`NSTemporaryDirectory()` with unique (`UUID`) names and clean up in `defer`.
Never touch the repo tree, `$HOME`, or fixed paths in tests. Process tests may
only invoke universally-present binaries (`/bin/echo`, `/bin/sh`).
