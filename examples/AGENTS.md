# AGENTS.md — examples/

Reserved for standalone, self-contained example files (single-file scripts or
snippets that are **not** part of any SPM target and are not compiled by
`swift build` or covered by tests). Currently empty.

If you add an example here:

- It must be runnable standalone (e.g. `swift examples/foo.swift`) or clearly
  marked as an excerpt.
- It follows the same style rules as library code (no force-unwraps, DocC-style
  comments) — examples get copied verbatim by readers.
- Anything that should be *guaranteed* to compile belongs in the library or a
  test instead; code in this directory is not CI-checked, so keep it minimal
  and reference it from the relevant `docs/` guide.
