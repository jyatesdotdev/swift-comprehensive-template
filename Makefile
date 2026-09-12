.PHONY: build test clean verify coverage security lint audit analyze periphery trivy

build:
	swift build

test:
	swift test

# Build, tests, and strict lint (matches CI, minus the coverage hang on GHA).
verify:
	swift build
	swift test
	swiftlint lint --strict

# Tests with coverage + the 80% threshold gate. Local-only: GitHub-hosted macOS
# hangs on `swift test --enable-code-coverage`.
coverage:
	./scripts/check-coverage.sh

clean:
	swift package clean

# --- Security targets ---

security:
	./scripts/security-scan.sh

lint:
	./scripts/security-scan.sh --tool swiftlint

audit:
	./scripts/security-scan.sh --tool audit

analyze:
	./scripts/security-scan.sh --tool analyze

periphery:
	./scripts/security-scan.sh --tool periphery

trivy:
	./scripts/security-scan.sh --tool trivy
