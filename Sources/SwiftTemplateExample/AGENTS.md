# AGENTS.md — SwiftTemplateExample Target

A deliberately minimal executable (`main.swift`, ~10 lines) that imports
`SwiftTemplate` and prints the version. It exists to prove the library links
and to give readers the smallest possible usage example.

Rules:

- **Keep it minimal.** Do not grow this into a demo app. Feature demonstrations
  belong in the library modules (as documented, compilable patterns), CLI
  demonstrations belong in `SwiftTemplateCLI`.
- It is a top-level `main.swift` (no `@main`). xcodebuild does not pass
  `-parse-as-library` for this target, so `@main` fails with "module that
  contains top-level code". Keep it as script-style top-level statements.
- It must build and run on Linux (`swift run SwiftTemplateExample`), so only
  portable `SwiftTemplate` API may be called here.
- No tests cover this target (it's excluded from the coverage story); keep it
  trivial enough that that stays true.
