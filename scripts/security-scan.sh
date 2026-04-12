#!/usr/bin/env bash
# security-scan.sh — Run all security scanning tools for the Swift project.
# Usage: ./scripts/security-scan.sh [--tool swiftlint|audit|analyze|periphery|trivy]
# Exit code: non-zero if any tool reports high-severity findings.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

FAILURES=0
SKIPPED=0
RUN_TOOL=""

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tool) RUN_TOOL="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

is_macos() { [[ "$(uname)" == "Darwin" ]]; }

has_tool() {
    if command -v "$1" &>/dev/null; then return 0; fi
    echo "⚠️  $1 not installed — skipping"
    SKIPPED=$((SKIPPED + 1))
    return 1
}

should_run() {
    [[ -z "$RUN_TOOL" || "$RUN_TOOL" == "$1" ]]
}

separator() { echo -e "\n━━━ $1 ━━━"; }

# --- SwiftLint ---
run_swiftlint() {
    separator "SwiftLint (security lint)"
    if ! has_tool swiftlint; then return; fi
    if swiftlint lint --strict --quiet 2>&1; then
        echo "✅ SwiftLint passed"
    else
        echo "❌ SwiftLint found issues"
        FAILURES=$((FAILURES + 1))
    fi
}

# --- swift package audit ---
run_audit() {
    separator "swift package audit (dependency vulnerabilities)"
    if ! has_tool swift; then return; fi
    local output
    if ! output=$(swift package audit 2>&1); then
        if echo "$output" | grep -q "Unknown subcommand"; then
            echo "⚠️  swift package audit not supported (requires Swift 6.1+) — skipping"
            SKIPPED=$((SKIPPED + 1))
            return
        fi
        echo "$output"
        echo "❌ Dependency audit found vulnerabilities"
        FAILURES=$((FAILURES + 1))
        return
    fi
    echo "$output"
    echo "✅ Dependency audit passed"
}

# --- xcodebuild analyze (macOS only) ---
run_analyze() {
    separator "Xcode Static Analyzer"
    if ! is_macos; then
        echo "⚠️  xcodebuild analyze — skipping (not macOS)"
        SKIPPED=$((SKIPPED + 1))
        return
    fi
    if ! has_tool xcodebuild; then return; fi
    local log
    log=$(xcodebuild analyze \
        -scheme SwiftTemplate \
        -destination 'platform=macOS' \
        -quiet \
        COMPILER_INDEX_STORE_ENABLE=NO 2>&1) || true
    if echo "$log" | grep -q "warning: .*analyzer"; then
        echo "❌ Static analyzer found issues"
        echo "$log" | grep "warning: .*analyzer"
        FAILURES=$((FAILURES + 1))
    else
        echo "✅ Static analysis passed"
    fi
}

# --- periphery (dead code) ---
run_periphery() {
    separator "Periphery (dead code detection)"
    if ! has_tool periphery; then return; fi
    if periphery scan --quiet 2>&1; then
        echo "✅ No dead code found"
    else
        echo "⚠️  Periphery found unused code (review recommended)"
        # Dead code is a warning, not a hard failure
    fi
}

# --- trivy (dependency/filesystem scan) ---
run_trivy() {
    separator "Trivy (dependency & filesystem scan)"
    if ! has_tool trivy; then return; fi
    if trivy fs --severity HIGH,CRITICAL --exit-code 1 --quiet . 2>&1; then
        echo "✅ Trivy scan passed"
    else
        echo "❌ Trivy found high/critical vulnerabilities"
        FAILURES=$((FAILURES + 1))
    fi
}

# --- Run ---
echo "🔒 Swift Security Scan"
echo "   Project: $PROJECT_DIR"
echo "   Date:    $(date -u +%Y-%m-%dT%H:%M:%SZ)"

should_run swiftlint  && run_swiftlint
should_run audit      && run_audit
should_run analyze    && run_analyze
should_run periphery  && run_periphery
should_run trivy      && run_trivy

# --- Summary ---
separator "Summary"
echo "Failures: $FAILURES | Skipped: $SKIPPED"
if [[ $FAILURES -gt 0 ]]; then
    echo "❌ Security scan FAILED"
    exit 1
fi
echo "✅ Security scan passed"
