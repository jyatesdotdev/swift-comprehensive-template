# AGENTS.md — scripts/

Two scripts live here:

- `security-scan.sh` — entry point for all security tooling. Invoked by the
  Makefile (`make security`, `make lint`, `make audit`, `make analyze`,
  `make periphery`, `make trivy`) and by `.github/workflows/security.yml`.
- `check-coverage.sh` — runs tests with coverage and enforces the 80% line
  threshold. Invoked by `make coverage` locally. CI does **not** run it:
  `swift test --enable-code-coverage` hangs on macos-14 GitHub runners.
  The exclusion regex (UI target, entry-point executables) is documented in
  its header — change it there, nowhere else.

## Script contract (preserve these behaviors)

- `--tool <name>` runs a single tool; no args runs everything.
- Missing tools are **skipped with a warning**, not failures — the script must
  work on machines that only have `swift`. (`has_tool` handles this.)
- Hard failures increment `FAILURES`; the script exits non-zero only if
  `FAILURES > 0`. Advisory findings (Periphery dead code) warn without failing.
- `set -euo pipefail` at the top; tool invocations that may fail are wrapped so
  they feed the FAILURES counter instead of aborting the script.

## Checklist: adding a scan tool

1. Write a `run_<tool>()` function following the existing shape: `separator`,
   `has_tool` guard, run, `✅`/`❌` result line, `FAILURES=$((FAILURES + 1))`
   on failure (or a `⚠️` warning if advisory).
2. Add `should_run <tool> && run_<tool>` to the run section **and** the tool
   name to the usage comment at the top.
3. Add a Makefile target that calls `./scripts/security-scan.sh --tool <tool>`.
4. Document the tool in `docs/SecurityScanningGuide.md`.
5. If CI should run it, check it's installed (or installable) in
   `.github/workflows/security.yml`.

## Conventions

- Platform-specific tools guard with `is_macos` and skip (with `SKIPPED`
  incremented) elsewhere — see `run_analyze`.
- Keep scripts POSIX-leaning bash, `shellcheck`-clean, with absolute paths
  derived from `SCRIPT_DIR`/`PROJECT_DIR` so they work from any CWD.
- New automation scripts belong here, follow the same header comment style
  (`# name.sh — purpose`, `# Usage:`), and must be `chmod +x`.
