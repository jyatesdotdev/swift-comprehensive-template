// MARK: - Systems Programming Module
// Foundation, Core Foundation, file I/O, process management, memory

import Foundation

// MARK: - 1. File System Operations

/// Type-safe wrapper around FileManager for common file I/O.
public enum FileSystem {

    /// Errors specific to file operations.
    public enum FSError: Error, CustomStringConvertible {
        /// The path does not exist.
        case notFound(String)
        /// A file or directory already exists at the path.
        case alreadyExists(String)
        /// Insufficient permissions to access the path.
        case permissionDenied(String)
        /// An I/O error occurred at the path.
        case ioError(String, underlying: Error)

        public var description: String {
            switch self {
            case .notFound(let p):        return "Not found: \(p)"
            case .alreadyExists(let p):   return "Already exists: \(p)"
            case .permissionDenied(let p): return "Permission denied: \(p)"
            case .ioError(let p, let e):  return "I/O error at \(p): \(e)"
            }
        }
    }

    // nonisolated(unsafe): FileManager.default is effectively immutable singleton.
    nonisolated(unsafe) private static let fm = FileManager.default

    /// Reads an entire file as `Data`.
    ///
    /// - Parameter path: The file path.
    /// - Returns: The file contents.
    /// - Throws: ``FSError/notFound(_:)`` or ``FSError/permissionDenied(_:)``.
    public static func readData(at path: String) throws -> Data {
        guard fm.fileExists(atPath: path) else { throw FSError.notFound(path) }
        guard let data = fm.contents(atPath: path) else { throw FSError.permissionDenied(path) }
        return data
    }

    /// Reads a file as a UTF-8 string.
    ///
    /// - Parameter path: The file path.
    /// - Returns: The file contents as a string.
    /// - Throws: ``FSError`` on read failure.
    public static func readString(at path: String) throws -> String {
        let data = try readData(at: path)
        return String(decoding: data, as: UTF8.self)
    }

    /// Writes `Data` to a path, creating intermediate directories as needed.
    ///
    /// - Parameters:
    ///   - data: The data to write.
    ///   - path: The destination file path.
    /// - Throws: ``FSError/ioError(_:underlying:)`` on write failure.
    public static func write(_ data: Data, to path: String) throws {
        let url = URL(fileURLWithPath: path)
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw FSError.ioError(path, underlying: error)
        }
    }

    /// Lists directory contents (non-recursive).
    ///
    /// - Parameter path: The directory path.
    /// - Returns: An array of entry names.
    /// - Throws: ``FSError/ioError(_:underlying:)`` on failure.
    public static func listDirectory(at path: String) throws -> [String] {
        do {
            return try fm.contentsOfDirectory(atPath: path)
        } catch {
            throw FSError.ioError(path, underlying: error)
        }
    }

    /// Recursively walks a directory, yielding relative paths.
    ///
    /// - Parameter root: The root directory path.
    /// - Returns: An array of relative paths.
    /// - Throws: ``FSError/notFound(_:)`` if the root doesn't exist.
    public static func walk(_ root: String) throws -> [String] {
        guard let enumerator = fm.enumerator(atPath: root) else {
            throw FSError.notFound(root)
        }
        var paths: [String] = []
        while let rel = enumerator.nextObject() as? String {
            paths.append(rel)
        }
        return paths
    }

    /// Returns file metadata via `FileAttributeKey`.
    ///
    /// - Parameter path: The file path.
    /// - Returns: A dictionary of file attributes.
    /// - Throws: ``FSError/ioError(_:underlying:)`` on failure.
    public static func attributes(at path: String) throws -> [FileAttributeKey: Any] {
        do {
            return try fm.attributesOfItem(atPath: path)
        } catch {
            throw FSError.ioError(path, underlying: error)
        }
    }

    /// Atomically writes data using a temporary file and rename.
    ///
    /// - Parameters:
    ///   - data: The data to write.
    ///   - path: The destination file path.
    /// - Throws: File system errors on write or rename failure.
    public static func atomicWrite(_ data: Data, to path: String) throws {
        let dir = URL(fileURLWithPath: path).deletingLastPathComponent()
        let tmp = dir.appendingPathComponent(UUID().uuidString)
        try data.write(to: tmp, options: .atomic)
        if fm.fileExists(atPath: path) { try fm.removeItem(atPath: path) }
        try fm.moveItem(at: tmp, to: URL(fileURLWithPath: path))
    }
}

// MARK: - 2. Environment & System Info

/// Access to environment variables and basic system information.
public enum SystemEnvironment {

    /// Returns the value of an environment variable, or `nil` if unset.
    ///
    /// - Parameter key: The environment variable name.
    /// - Returns: The value, or `nil`.
    public static func get(_ key: String) -> String? {
        ProcessInfo.processInfo.environment[key]
    }

    /// All environment variables as a dictionary.
    public static var all: [String: String] {
        ProcessInfo.processInfo.environment
    }

    /// The host name of the machine.
    public static var hostName: String {
        ProcessInfo.processInfo.hostName
    }

    /// The OS version as a `"major.minor.patch"` string.
    public static var osVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    /// Physical memory in bytes.
    public static var physicalMemory: UInt64 {
        ProcessInfo.processInfo.physicalMemory
    }

    /// Active processor count.
    public static var processorCount: Int {
        ProcessInfo.processInfo.activeProcessorCount
    }
}

// MARK: - 3. Process Management (macOS / Linux)

#if os(macOS) || os(Linux)
/// Launch and manage child processes.
public enum Shell {

    /// Result of a process execution.
    public struct RunResult: Sendable {
        /// The process exit code.
        public let exitCode: Int32
        /// Captured standard output.
        public let stdout: String
        /// Captured standard error.
        public let stderr: String
        /// `true` if the exit code is `0`.
        public var succeeded: Bool { exitCode == 0 }
    }

    /// Runs a command synchronously, capturing stdout and stderr.
    ///
    /// - Parameters:
    ///   - command: Path to the executable.
    ///   - arguments: Command-line arguments.
    /// - Returns: A ``RunResult`` with exit code and captured output.
    public static func run(_ command: String, arguments: [String] = []) -> RunResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return RunResult(exitCode: -1, stdout: "", stderr: error.localizedDescription)
        }

        let out = String(decoding: outPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let err = String(decoding: errPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        return RunResult(exitCode: process.terminationStatus, stdout: out, stderr: err)
    }

    /// Runs a shell expression via `/bin/sh -c`.
    ///
    /// - Parameter expression: The shell command string.
    /// - Returns: A ``RunResult`` with exit code and captured output.
    public static func sh(_ expression: String) -> RunResult {
        run("/bin/sh", arguments: ["-c", expression])
    }

    /// Async variant of ``run(_:arguments:)`` using structured concurrency.
    ///
    /// - Parameters:
    ///   - command: Path to the executable.
    ///   - arguments: Command-line arguments.
    /// - Returns: A ``RunResult`` with exit code and captured output.
    public static func runAsync(_ command: String, arguments: [String] = []) async -> RunResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: run(command, arguments: arguments))
            }
        }
    }
}
#endif

// MARK: - 4. Pipes & File Handles

/// Demonstrates FileHandle-based streaming I/O.
public enum StreamIO {

    /// Reads a file in fixed-size chunks, calling a handler for each.
    ///
    /// - Parameters:
    ///   - path: The file path.
    ///   - chunkSize: Bytes per chunk. Defaults to 64 KB.
    ///   - handler: A closure called with each chunk of data.
    /// - Throws: ``FileSystem/FSError/notFound(_:)`` if the file doesn't exist, or rethrows handler errors.
    public static func readChunked(
        path: String,
        chunkSize: Int = 64 * 1024,
        handler: (Data) throws -> Void
    ) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw FileSystem.FSError.notFound(path)
        }
        guard let handle = FileHandle(forReadingAtPath: path) else {
            throw FileSystem.FSError.notFound(path)
        }
        defer { handle.closeFile() }
        while true {
            let chunk = handle.readData(ofLength: chunkSize)
            if chunk.isEmpty { break }
            try handler(chunk)
        }
    }

    /// Creates a connected read/write file handle pair for IPC.
    ///
    /// - Returns: A tuple of `(read, write)` file handles.
    public static func makePipe() -> (read: FileHandle, write: FileHandle) {
        let pipe = Pipe()
        return (pipe.fileHandleForReading, pipe.fileHandleForWriting)
    }
}

// MARK: - 5. Unsafe Memory & Pointers

/// Demonstrates safe patterns for working with unsafe pointers.
public enum UnsafeMemory {

    /// Allocates a temporary buffer, passes it to `body`, then deallocates.
    ///
    /// - Parameters:
    ///   - type: The element type.
    ///   - count: Number of elements to allocate.
    ///   - body: A closure that receives the mutable buffer pointer.
    public static func withManualBuffer<T>(
        of type: T.Type,
        count: Int,
        body: (UnsafeMutableBufferPointer<T>) throws -> Void
    ) rethrows {
        let ptr = UnsafeMutablePointer<T>.allocate(capacity: count)
        defer { ptr.deallocate() }
        let buffer = UnsafeMutableBufferPointer(start: ptr, count: count)
        try body(buffer)
    }

    /// Reinterprets the bytes of a source array as a different type.
    ///
    /// - Parameters:
    ///   - source: The source array.
    ///   - type: The target element type.
    /// - Returns: An array of the target type.
    public static func reinterpret<S, D>(_ source: [S], as _: D.Type) -> [D] {
        source.withUnsafeBytes { raw in
            let count = raw.count / MemoryLayout<D>.stride
            return Array(raw.bindMemory(to: D.self).prefix(count))
        }
    }

    /// Copies bytes between raw memory regions.
    ///
    /// - Parameters:
    ///   - src: Source pointer.
    ///   - dst: Destination pointer.
    ///   - count: Number of bytes to copy.
    public static func copyBytes(from src: UnsafeRawPointer, to dst: UnsafeMutableRawPointer, count: Int) {
        dst.copyMemory(from: src, byteCount: count)
    }
}

// MARK: - 6. Core Foundation Bridging

#if canImport(CoreFoundation)
import CoreFoundation

/// Patterns for bridging between Swift and Core Foundation types.
public enum CFBridging {

    /// Demonstrates toll-free bridging: Swift String → CFString → Swift String.
    ///
    /// - Parameter value: The string to round-trip.
    /// - Returns: The same string after bridging through CFString.
    public static func cfStringRoundTrip(_ value: String) -> String {
        let cf = value as CFString          // toll-free bridge to CF
        let length = CFStringGetLength(cf)  // use CF API
        _ = length
        return cf as String                 // bridge back
    }

    /// Demonstrates CFDictionary bridging.
    ///
    /// - Returns: A Swift dictionary after round-tripping through CFDictionary.
    public static func cfDictionaryExample() -> [String: Any] {
        let dict: NSDictionary = ["key": "value", "number": 42]
        let cf = dict as CFDictionary
        let count = CFDictionaryGetCount(cf)
        _ = count
        return (cf as? [String: Any]) ?? [:]
    }

    /// Schedules a one-shot timer on the current run loop via CFRunLoopTimer.
    ///
    /// - Parameters:
    ///   - seconds: Delay before firing.
    ///   - handler: The closure to invoke when the timer fires.
    public static func scheduleTimer(after seconds: Double, handler: @escaping () -> Void) {
        let fire = CFAbsoluteTimeGetCurrent() + seconds
        var context = CFRunLoopTimerContext()
        // Store handler in an opaque pointer via Unmanaged.
        let boxed = Unmanaged.passRetained(handler as AnyObject)
        context.info = boxed.toOpaque()
        context.release = { ptr in
            guard let ptr else { return }
            Unmanaged<AnyObject>.fromOpaque(ptr).release()
        }
        let timer = CFRunLoopTimerCreate(
            kCFAllocatorDefault, fire, 0, 0, 0,
            { _, info in
                guard let info else { return }
                let fn = Unmanaged<AnyObject>.fromOpaque(info).takeUnretainedValue()
                (fn as? (() -> Void))?()
            },
            &context
        )
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, .defaultMode)
    }
}
#endif

// MARK: - 7. Signal Handling

#if canImport(Glibc) || canImport(Darwin)
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// Basic POSIX signal handling.
public enum Signals {

    /// Installs a signal handler for the given signal.
    ///
    /// - Parameters:
    ///   - sig: The signal number (e.g., `SIGINT`, `SIGTERM`).
    ///   - handler: A C-convention handler. Only async-signal-safe operations are permitted.
    public static func trap(_ sig: Int32, handler: @escaping @convention(c) (Int32) -> Void) {
        signal(sig, handler)
    }

    /// Ignores the given signal.
    ///
    /// - Parameter sig: The signal number to ignore.
    public static func ignore(_ sig: Int32) {
        signal(sig, SIG_IGN)
    }

    /// Restores the default behavior for the given signal.
    ///
    /// - Parameter sig: The signal number to restore.
    public static func restore(_ sig: Int32) {
        signal(sig, SIG_DFL)
    }
}
#endif
