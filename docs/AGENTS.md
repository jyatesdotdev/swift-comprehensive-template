# AGENTS.md — docs/

Human-facing Markdown guides. Structure: getting-started docs (`TUTORIAL.md`,
`ARCHITECTURE.md`, `TOOLCHAIN.md`, `EXTENDING.md`), one guide per library module
(`ConcurrencyGuide.md`, `RenderingGuide.md`, `SystemsGuide.md`, `HPCGuide.md`,
`SimulationGuide.md`, `UIGuide.md`), and reference guides (`BestPractices.md`, `CLIGuide.md`,
`TestingGuide.md`, `CrossPlatformGuide.md`, `ThirdPartyGuide.md`,
`SecurityScanningGuide.md`, `DocumentationGuide.md`).

API-level documentation does **not** live here — it lives as DocC comments in
the source and in `Sources/SwiftTemplate/SwiftTemplate.docc/`. These guides
explain concepts and point at the code.

## Update matrix — when code changes, docs must follow

| You changed | Update |
|---|---|
| A module's public API or patterns | That module's `*Guide.md` |
| Added/removed a module, target, or dependency | `ARCHITECTURE.md` (+ README module table) |
| CLI commands | `CLIGuide.md` |
| UI components, view models, demo app | `UIGuide.md` |
| Test tooling/conventions | `TestingGuide.md` |
| Lint rules, security scan tools | `SecurityScanningGuide.md` |
| How to extend the template | `EXTENDING.md` |

## When a guide conflicts with the code

The **code and CI are the source of truth** — when a guide conflicts, fix the
guide, never copy its stale pattern into code. Watch especially for XCTest
examples (the repo is Swift Testing only; a stale-doc cleanup already removed
them once — don't let them creep back in) and for CI descriptions drifting from
the actual workflows in `.github/workflows/`.

## Writing style

Match the existing guides: task-oriented headings, short prose, fenced code
blocks that actually compile against the current API, tables for
command/option/file listings, and relative links between guides
(`[ARCHITECTURE.md](ARCHITECTURE.md)`). Every code snippet you add or edit
should be checked against the real source in `Sources/` — snippets drift, code
doesn't.
