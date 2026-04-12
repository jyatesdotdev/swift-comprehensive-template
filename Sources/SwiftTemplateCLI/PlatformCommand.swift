import ArgumentParser
import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// Demonstrates cross-platform (macOS + Linux) compatibility patterns.
struct PlatformCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "platform",
        abstract: "Show platform info and demonstrate cross-platform patterns.",
        subcommands: [InfoSubcommand.self, PathsSubcommand.self, SignalSubcommand.self]
    )
}

// MARK: - Platform Detection

/// Cross-platform system info using conditional compilation.
enum Platform {
    static var name: String {
        #if os(macOS)
        return "macOS"
        #elseif os(Linux)
        return "Linux"
        #elseif os(Windows)
        return "Windows"
        #else
        return "Unknown"
        #endif
    }

    static var arch: String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }

    /// Home directory — resolved differently per platform.
    static var homeDirectory: String {
        #if os(macOS) || os(Linux)
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            return home
        }
        #endif
        return FileManager.default.homeDirectoryForCurrentUser.path
    }

    /// Config directory following platform conventions.
    static var configDirectory: String {
        #if os(macOS)
        return homeDirectory + "/Library/Application Support"
        #elseif os(Linux)
        // XDG Base Directory Specification
        return ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"]
            ?? (homeDirectory + "/.config")
        #else
        return homeDirectory
        #endif
    }

    /// Cache directory following platform conventions.
    static var cacheDirectory: String {
        #if os(macOS)
        return homeDirectory + "/Library/Caches"
        #elseif os(Linux)
        return ProcessInfo.processInfo.environment["XDG_CACHE_HOME"]
            ?? (homeDirectory + "/.cache")
        #else
        return NSTemporaryDirectory()
        #endif
    }

    /// Hostname — uses POSIX gethostname on both platforms.
    static var hostname: String {
        var buffer = [CChar](repeating: 0, count: 256)
        gethostname(&buffer, 256)
        return buffer.withUnsafeBufferPointer {
            String(decoding: $0.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self)
        }
    }
}

// MARK: - Info Subcommand

extension PlatformCommand {
    struct InfoSubcommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "info",
            abstract: "Print detected platform information."
        )

        func run() {
            print("OS:       \(Platform.name)")
            print("Arch:     \(Platform.arch)")
            print("Hostname: \(Platform.hostname)")

            // OS-specific details
            #if os(macOS)
            let version = ProcessInfo.processInfo.operatingSystemVersion
            print("Version:  \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)")
            #elseif os(Linux)
            // Read /etc/os-release for distro info
            if let release = try? String(contentsOfFile: "/etc/os-release", encoding: .utf8),
               let pretty = release.split(separator: "\n").first(where: { $0.hasPrefix("PRETTY_NAME=") }) {
                let name = pretty.dropFirst("PRETTY_NAME=".count).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                print("Distro:   \(name)")
            }
            #endif
        }
    }
}

// MARK: - Paths Subcommand

extension PlatformCommand {
    struct PathsSubcommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "paths",
            abstract: "Show platform-appropriate directories (config, cache, temp)."
        )

        func run() {
            print("Home:   \(Platform.homeDirectory)")
            print("Config: \(Platform.configDirectory)")
            print("Cache:  \(Platform.cacheDirectory)")
            print("Temp:   \(NSTemporaryDirectory())")
        }
    }
}

// MARK: - Signal Handling Subcommand

extension PlatformCommand {
    struct SignalSubcommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "signals",
            abstract: "Demonstrate cross-platform POSIX signal handling."
        )

        func run() {
            // POSIX signal handling works on both macOS and Linux
            signal(SIGINT) { _ in
                print("\nCaught SIGINT — cleaning up...")
                // Perform cleanup here
                _Exit(0)
            }

            print("Signal handler installed. Press Ctrl+C to test (or it will exit in 3s).")
            print("Tip: Use signal() or DispatchSource for cross-platform signal handling.")

            // Brief sleep to demonstrate, then exit normally
            Thread.sleep(forTimeInterval: 3)
            print("Exiting normally.")
        }
    }
}
