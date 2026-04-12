# Security Scanning Guide

This project integrates five security scanning tools into the build process. All tools can be run individually or together via a single command.

## Quick Start

```bash
# Run all security scans
make security

# Run a single tool
make lint        # SwiftLint
make audit       # swift-package-audit
make analyze     # xcodebuild analyze (macOS only)
make periphery   # dead code detection
make trivy       # dependency/filesystem scan
```

Or use the script directly:

```bash
./scripts/security-scan.sh              # all tools
./scripts/security-scan.sh --tool trivy # single tool
```

## Tools

### 1. SwiftLint — Security Linting

Catches unsafe Swift patterns at compile time.

**Rules enforced as errors (fail CI):**
- `force_cast` — unsafe type casting
- `force_try` — unhandled throwing calls
- `force_unwrapping` — forced optional unwrapping
- `empty_catch` — silently swallowed errors

**Rules enforced as warnings:**
- `implicitly_unwrapped_optional` — implicit unwraps (except IBOutlets)
- `fatal_error_message` — fatalError calls without messages

**Configuration:** `.swiftlint.yml`

SwiftLint also runs automatically during `swift build` via the SPM build tool plugin (`SwiftLintPlugins`).

**Install:** `brew install swiftlint`

### 2. swift-package-audit — Dependency Vulnerabilities

Checks `Package.resolved` against known vulnerability databases. Any finding fails the scan.

**Install:** `npm install -g swift-package-audit`

### 3. Xcode Static Analyzer (macOS only)

Runs `xcodebuild analyze` to detect memory issues, logic errors, and API misuse. Automatically skipped on Linux.

**Requires:** Xcode (pre-installed on macOS CI runners)

### 4. Periphery — Dead Code Detection

Detects unused declarations. Findings are reported as warnings and do **not** fail CI — dead code is informational, not a security vulnerability.

**Install:** `brew install peripheryapp/periphery/periphery`

### 5. Trivy — Dependency & Filesystem Scanning

Scans the project filesystem for known vulnerabilities. Only HIGH and CRITICAL severity findings fail the scan.

**Install:**
- macOS: `brew install trivy`
- Linux: See [Trivy installation docs](https://aquasecurity.github.io/trivy/)

## CI Integration

The GitHub Actions workflow (`.github/workflows/security.yml`) runs on every push and PR to `main`.

**Matrix:**

| Runner | Tools Run |
|--------|-----------|
| macOS (macos-14) | All five tools |
| Linux (ubuntu-latest) | swift-package-audit, Trivy (others skipped) |

**Security gate:** The workflow fails if `security-scan.sh` exits non-zero, which happens when any tool (except Periphery) reports findings.

## Behavior Summary

| Tool | Fail CI? | Platform |
|------|----------|----------|
| SwiftLint | Yes (on errors) | macOS |
| swift-package-audit | Yes | macOS, Linux |
| xcodebuild analyze | Yes | macOS only |
| Periphery | No (warnings only) | macOS |
| Trivy | Yes (HIGH/CRITICAL) | macOS, Linux |

Missing tools are gracefully skipped with a warning — the scan does not fail because a tool is absent.

## Adding New Rules

To add SwiftLint rules, edit `.swiftlint.yml`. Security-critical rules should use `severity: error` so they block CI:

```yaml
my_custom_rule:
  severity: error
```

To add a new scanning tool, add a function to `scripts/security-scan.sh` following the existing pattern, then add a corresponding Makefile target.

---

> **See also:** [ARCHITECTURE.md](ARCHITECTURE.md) · [TOOLCHAIN.md](TOOLCHAIN.md) · [TUTORIAL.md](TUTORIAL.md) · [EXTENDING.md](EXTENDING.md)
