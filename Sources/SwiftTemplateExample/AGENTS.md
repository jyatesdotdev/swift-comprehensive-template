# AGENTS.md — SwiftTemplateExample Target

A deliberately minimal executable (`main.swift`, ~10 lines) that imports
`SwiftTemplate` and prints the version. It exists to prove the library links
and to give readers the smallest possible usage example.

Rules:

- **Keep it minimal.** Do not grow this into a demo app. Feature demonstrations
  belong in the library modules (as documented, compilable patterns), CLI
  demonstrations belong in `SwiftTemplateCLI`.
- It uses the `@main struct` + `static func main()` pattern. If you add any
  async demonstration, switch to `static func main() async` — don't block with
  semaphores.
- It must build and run on Linux (`swift run SwiftTemplateExample`), so only
  portable `SwiftTemplate` API may be called here.
- No tests cover this target (it's excluded from the coverage story); keep it
  trivial enough that that stays true.
