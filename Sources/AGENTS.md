# AGENTS.md — Sources/

Router only — the rules live one level down:

- `SwiftTemplate/AGENTS.md` — the core library (plus per-domain guides in
  `Concurrency/`, `HPC/`, `Rendering/`, `Simulation/`, `Systems/`).
- `SwiftTemplateUI/AGENTS.md` — SwiftUI building blocks (Apple-only library).
- `SwiftTemplateCLI/AGENTS.md` — the CLI executable.
- `SwiftTemplateUIDemo/AGENTS.md` — the macOS UI demo app.
- `SwiftTemplateExample/AGENTS.md` — the minimal example executable.

Two facts that apply to everything under `Sources/`:

1. Targets are declared in `/Package.swift` with explicit `path:` values — a new
   top-level directory here does nothing until registered there (see
   `docs/EXTENDING.md`).
2. Library code (`SwiftTemplate/`, `SwiftTemplateUI/`) is `public` API with
   mandatory DocC comments and StrictConcurrency; executable code
   (`SwiftTemplateCLI/`, `SwiftTemplateUIDemo/`, `SwiftTemplateExample/`)
   stays `internal`. Shared logic goes in a library, never duplicated into an
   executable.
3. Every target's directory contains non-Swift files (like these guides) only
   if they are listed in that target's `exclude:` in `Package.swift` —
   otherwise SPM emits "unhandled file" warnings.
