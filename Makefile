.PHONY: build test clean security lint audit analyze periphery trivy

build:
	swift build

test:
	swift test

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
