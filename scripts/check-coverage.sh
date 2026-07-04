#!/usr/bin/env bash
# check-coverage.sh — Run tests with coverage and enforce a minimum threshold.
# Usage: ./scripts/check-coverage.sh [threshold]   (default: 80)
#
# The gate covers the core library and CLI. Excluded from measurement:
#   - Tests/ and .build/
#   - SwiftTemplateUI (SwiftUI view bodies and MTKView delegates need UI tests,
#     not unit tests; view-model logic there IS unit-tested, just not gated)
#   - SwiftTemplateUIDemo / SwiftTemplateExample (entry-point executables)
# Requires macOS (xcrun llvm-cov).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

THRESHOLD="${1:-80.0}"
IGNORE_REGEX='\.build|Tests|SwiftTemplateUI|SwiftTemplateUIDemo|SwiftTemplateExample'

swift test --enable-code-coverage --parallel

BIN_PATH=$(swift build --show-bin-path)
PROFDATA=$(find "$BIN_PATH" -name 'default.profdata' | head -1)
TEST_BIN=$(find "$BIN_PATH" -name 'SwiftTemplatePackageTests' -type f | head -1)
if [[ -z "$TEST_BIN" ]]; then
    TEST_BIN="$BIN_PATH/SwiftTemplatePackageTests.xctest/Contents/MacOS/SwiftTemplatePackageTests"
fi
if [[ -z "$PROFDATA" || ! -f "$TEST_BIN" ]]; then
    echo "❌ Could not locate coverage data ($PROFDATA) or test binary ($TEST_BIN)"
    exit 1
fi

xcrun llvm-cov report \
    "$TEST_BIN" \
    -instr-profile "$PROFDATA" \
    -ignore-filename-regex "$IGNORE_REGEX"

COVERAGE=$(xcrun llvm-cov report \
    "$TEST_BIN" \
    -instr-profile "$PROFDATA" \
    -ignore-filename-regex "$IGNORE_REGEX" \
    | grep -E '^TOTAL' | awk '{print $4}' | tr -d '%')

echo "Line coverage: ${COVERAGE}% (threshold: ${THRESHOLD}%)"
if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
    echo "❌ Coverage ${COVERAGE}% is below the ${THRESHOLD}% threshold"
    exit 1
fi
echo "✅ Coverage gate passed"
