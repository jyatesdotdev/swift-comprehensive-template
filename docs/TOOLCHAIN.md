# Toolchain & Tools

Required and optional tools for building, testing, linting, and scanning the SwiftTemplate project.

> See also: [ARCHITECTURE.md](ARCHITECTURE.md) · [TUTORIAL.md](TUTORIAL.md) · [SecurityScanningGuide.md](SecurityScanningGuide.md)

## Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Swift** | 5.9+ to **build**; 6.x to **test** (`swift-tools-version: 5.9`, Swift Testing needs 6) |
| **Xcode** | 16.2+ | Tests, Apple platform builds, static analyzer (macOS only) |
| **SwiftLint** | 0.58+ | Security-focused linting (also runs via SPM build plugin) |
| **`swift package audit`** | Swift 6.1+ | Checks resolved pins against vulnerability databases |
| **Periphery** | latest | Dead code detection |
| **Trivy** | latest | Dependency & filesystem vulnerability scanning |

## Optional Tools

| Tool | Purpose |
|------|---------|
| **swift-format** | Code formatting (not currently integrated — add via SPM plugin if desired) |
| **swift-docc-plugin** | Documentation generation (already an SPM dependency, v1.4.3) |

## SPM Dependencies

These are fetched automatically by `swift build`:

| Package | Version | Used By |
|---------|---------|---------|
| [swift-argument-parser](https://github.com/apple/swift-argument-parser) | 1.5.0+ | `SwiftTemplateCLI` target |
| [swift-docc-plugin](https://github.com/swiftlang/swift-docc-plugin) | 1.4.3+ | Documentation generation |
| [SwiftLintPlugins](https://github.com/SimplyDanny/SwiftLintPlugins) | 0.58.0+ | Build-time linting on `SwiftTemplate` target |

## Installation — macOS

```bash
# Swift & Xcode — install from the Mac App Store or https://developer.apple.com/xcode/
xcode-select --install   # command-line tools (if Xcode is not installed)

# Homebrew packages
brew install swiftlint
brew install peripheryapp/periphery/periphery
brew install trivy
```

Verify:

```bash
swift --version          # Swift 5.9+ to build; 6.x to test
swiftlint version        # 0.58.0 or later
periphery version
trivy --version
swift package audit      # Swift 6.1+; older toolchains skip
```

## Installation — Linux (Ubuntu 22.04+)

```bash
# Swift — use swiftlang.org or the setup-swift GitHub Action
# See https://www.swift.org/install/linux/
# Example for Ubuntu 22.04 (6.x toolchain required to run tests):
wget https://download.swift.org/swift-6.0.3-release/ubuntu2204/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu22.04.tar.gz
tar xzf swift-6.0.3-RELEASE-ubuntu22.04.tar.gz
export PATH="$(pwd)/swift-6.0.3-RELEASE-ubuntu22.04/usr/bin:$PATH"

# Trivy
sudo apt-get install -y wget apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
  | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install -y trivy
```

> **Note:** SwiftLint, Periphery, and `xcodebuild analyze` are macOS-only. On Linux, the security scan gracefully skips them.

## Platform Tool Availability

| Tool | macOS | Linux |
|------|-------|-------|
| Swift compiler | ✅ | ✅ |
| SwiftLint | ✅ | ❌ (skipped) |
| `swift package audit` | ✅ (6.1+) | ✅ (6.1+) |
| xcodebuild analyze | ✅ | ❌ (skipped) |
| Periphery | ✅ | ❌ (skipped) |
| Trivy | ✅ | ✅ |

## Editor Setup

### Xcode

1. Open `Package.swift` in Xcode (File → Open, or `open Package.swift` from terminal).
2. Xcode resolves SPM dependencies automatically.
3. SwiftLint runs during builds via the `SwiftLintBuildToolPlugin` — no extra configuration needed.
4. Select a scheme (`SwiftTemplate`, `SwiftTemplateExample`, or `SwiftTemplateCLI`) from the scheme picker.
5. Use Product → Analyze (⇧⌘B) to run the Xcode static analyzer.

### VS Code + SourceKit-LSP

1. Install the [Swift extension](https://marketplace.visualstudio.com/items?itemName=sswg.swift-lang) (includes SourceKit-LSP).
2. Open the project folder in VS Code.
3. The extension auto-detects `Package.swift` and provides:
   - Code completion, jump-to-definition, inline diagnostics
   - Build/test tasks via the Swift toolbar
4. For SwiftLint integration, install the [SwiftLint extension](https://marketplace.visualstudio.com/items?itemName=vknabel.vscode-swiftlint) and ensure `swiftlint` is on your `$PATH`.
5. Add to `.vscode/settings.json` for best results:

```json
{
  "swift.path": "/usr/bin",
  "editor.formatOnSave": true,
  "swiftlint.enable": true
}
```

### Other Editors

Any editor with LSP support works with SourceKit-LSP. Ensure `sourcekit-lsp` is on your `$PATH` (ships with the Swift toolchain) and configure your editor's LSP client to use it.

## CI Integration

The GitHub Actions workflow (`.github/workflows/security.yml`) installs tools on **macos-15** and runs the full scan there. There is no Linux CI runner; Linux tool notes below are for local use.

See [SecurityScanningGuide.md](SecurityScanningGuide.md) for details on CI behavior and failure modes.

## Makefile Targets

```bash
make build       # swift build
make test        # swift test
make clean       # swift package clean
make security    # Run all security scans
make lint        # SwiftLint only
make audit       # swift package audit only
make analyze     # xcodebuild analyze (macOS only)
make periphery   # Dead code detection
make trivy       # Trivy filesystem scan
```
