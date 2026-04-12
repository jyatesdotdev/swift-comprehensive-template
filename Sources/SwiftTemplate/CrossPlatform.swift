// MARK: - Cross-Platform Development Patterns
// Conditional compilation, platform abstraction, portable APIs

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(os)
import os
#endif

// MARK: - 1. Platform Detection

/// Runtime and compile-time platform identification.
public enum Platform {

    /// Compile-time platform identifier.
    public enum OS: String, Sendable {
        case macOS, iOS, tvOS, watchOS, visionOS, linux, windows, unknown
    }

    /// The OS this binary was compiled for.
    public static var current: OS {
        #if os(macOS)
        return .macOS
        #elseif os(iOS)
        return .iOS
        #elseif os(tvOS)
        return .tvOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(visionOS)
        return .visionOS
        #elseif os(Linux)
        return .linux
        #elseif os(Windows)
        return .windows
        #else
        return .unknown
        #endif
    }

    /// `true` when running on an Apple platform (any Darwin variant).
    public static var isApple: Bool {
        #if canImport(Darwin)
        return true
        #else
        return false
        #endif
    }

    /// Architecture string (`arm64`, `x86_64`, etc.).
    public static var architecture: String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }
}

// MARK: - 2. Portable File Paths

/// Cross-platform path utilities that work on Darwin and Linux.
public enum PortablePath {

    /// Home directory — works on macOS, iOS (sandbox), and Linux.
    public static var home: String {
        #if canImport(Darwin)
        return NSHomeDirectory()
        #else
        return ProcessInfo.processInfo.environment["HOME"] ?? "/"
        #endif
    }

    /// Temporary directory.
    public static var temp: String {
        NSTemporaryDirectory()
    }

    /// Joins path components with `/`.
    ///
    /// - Parameter components: The path segments to join.
    /// - Returns: A single path string.
    public static func join(_ components: String...) -> String {
        components.joined(separator: "/")
    }
}

// MARK: - 3. Platform-Abstracted Logging

/// Minimal cross-platform logger using `os.Logger` on Apple, stderr on Linux.
public enum PlatformLogger {

    /// Log severity level.
    public enum Level: String, Sendable { case debug, info, warning, error }

    /// Emits a log message at the given level.
    ///
    /// - Parameters:
    ///   - level: The severity level.
    ///   - message: An autoclosure producing the log message.
    public static func log(_ level: Level, _ message: @autoclosure () -> String) {
        let msg = message()
        #if canImport(os)
        let logger = os.Logger(subsystem: "SwiftTemplate", category: "app")
        switch level {
        case .debug:   logger.debug("\(msg)")
        case .info:    logger.info("\(msg)")
        case .warning: logger.warning("\(msg)")
        case .error:   logger.error("\(msg)")
        }
        #else
        let tag = level.rawValue.uppercased()
        let line = "[\(tag)] \(msg)\n"
        if let data = line.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
        #endif
    }
}

// MARK: - 4. Conditional Feature Availability

/// Demonstrates compile-time feature flags and availability checks.
public enum FeatureFlags {

    /// `true` if Metal GPU compute is available at compile time.
    public static var hasGPU: Bool {
        #if canImport(Metal)
        return true
        #else
        return false
        #endif
    }

    /// `true` if SwiftUI is available.
    public static var hasSwiftUI: Bool {
        #if canImport(SwiftUI)
        return true
        #else
        return false
        #endif
    }

    /// `true` if Combine is available.
    public static var hasCombine: Bool {
        #if canImport(Combine)
        return true
        #else
        return false
        #endif
    }

    /// Runtime availability check example (Apple platforms only).
    #if canImport(Darwin)
    @available(macOS 14, iOS 17, *)
    public static func requiresModernOS() -> Bool { true }
    #endif
}

// MARK: - 5. Cross-Platform Networking

/// Portable HTTP GET using URLSession (available on all Swift platforms).
public enum PortableHTTP {

    /// Errors from HTTP operations.
    public enum HTTPError: Error {
        /// The server returned a non-2xx status code.
        case badStatus(Int)
        /// No data was received.
        case noData
    }

    /// Performs an async HTTP GET request.
    ///
    /// - Parameter url: The URL to fetch.
    /// - Returns: The response body as `Data`.
    /// - Throws: ``HTTPError/badStatus(_:)`` on non-2xx responses, or network errors.
    public static func get(url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw HTTPError.badStatus(http.statusCode)
        }
        return data
    }
}

// MARK: - 6. Endianness & Byte Order

/// Portable byte-order utilities for cross-platform binary data.
public enum ByteOrder {

    /// `true` if the host uses little-endian byte order.
    public static var isLittleEndian: Bool {
        UInt16(littleEndian: 1) == 1
    }

    /// Converts a `UInt32` to big-endian (network byte order) bytes.
    ///
    /// - Parameter value: The value to convert.
    /// - Returns: A 4-byte array in big-endian order.
    public static func toBigEndian(_ value: UInt32) -> [UInt8] {
        let be = value.bigEndian
        return withUnsafeBytes(of: be) { Array($0) }
    }

    /// Reads a `UInt32` from big-endian bytes.
    ///
    /// - Parameter bytes: At least 4 bytes in big-endian order.
    /// - Returns: The decoded value, or `nil` if fewer than 4 bytes.
    public static func fromBigEndian(_ bytes: [UInt8]) -> UInt32? {
        guard bytes.count >= 4 else { return nil }
        return bytes.withUnsafeBufferPointer { buf -> UInt32? in
            guard let baseAddress = buf.baseAddress else { return nil }
            return baseAddress.withMemoryRebound(to: UInt32.self, capacity: 1) {
                UInt32(bigEndian: $0.pointee)
            }
        }
    }
}

// MARK: - 7. Compile-Time Diagnostics

/// Demonstrates `@available` deprecation and conditional compilation patterns.
public enum CompileDiagnostics {

    // #warning("TODO: implement caching layer")       // flags unfinished work
    // #error("Unsupported platform")                  // blocks unsupported targets

    @available(*, deprecated, message: "Use PortableHTTP.get instead")
    public static func legacyFetch() {}
}
