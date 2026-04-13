// MARK: - Third-Party Integration Patterns
// Demonstrates how to abstract over external dependencies so they can be
// swapped, mocked, or conditionally compiled without touching call sites.

import Foundation

// MARK: - Protocol-Based Abstraction

/// Abstract HTTP client — conform URLSession (or Alamofire, etc.) to this.
public protocol HTTPClient: Sendable {
    /// Fetches data from a URL.
    ///
    /// - Parameter url: The URL to fetch.
    /// - Returns: A tuple of response data and URL response.
    /// - Throws: Network or server errors.
    func data(from url: URL) async throws -> (Data, URLResponse)
}

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession: HTTPClient {
    public func data(from url: URL) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)
        return try await withCheckedThrowingContinuation { cont in
            dataTask(with: url) { d, r, e in
                if let e {
                    cont.resume(throwing: e)
                } else if let d, let r {
                    cont.resume(returning: (d, r))
                } else {
                    cont.resume(throwing: URLError(.badServerResponse))
                }
            }.resume()
        }
        #else
        return try await self.data(from: url, delegate: nil)
        #endif
    }
}

// MARK: - Logging Abstraction

/// Minimal logging protocol — back with swift-log, os_log, or print.
public protocol Logger: Sendable {
    /// Emits a log message at the given level.
    ///
    /// - Parameters:
    ///   - level: The severity level.
    ///   - message: An autoclosure producing the log message.
    func log(_ level: LogLevel, _ message: @autoclosure () -> String)
}

/// Log severity level.
public enum LogLevel: String, Sendable { case debug, info, warning, error }

/// Default print-based logger.
public struct PrintLogger: Logger, Sendable {
    /// Creates a print logger.
    public init() {}

    /// Logs a message to standard output.
    ///
    /// - Parameters:
    ///   - level: The severity level.
    ///   - message: An autoclosure producing the log message.
    public func log(_ level: LogLevel, _ message: @autoclosure () -> String) {
        print("[\(level.rawValue.uppercased())] \(message())")
    }
}

// MARK: - Dependency Container

/// Lightweight dependency container — swap `.live` for `.mock` in tests.
public struct AppDependencies: Sendable {
    /// The HTTP client used for network requests.
    public var http: any HTTPClient
    /// The logger used for diagnostic output.
    public var logger: any Logger

    /// Production dependencies using URLSession and print logging.
    public static let live = AppDependencies(
        http: URLSession.shared,
        logger: PrintLogger()
    )
}

// MARK: - Service Using Abstractions

/// A service that fetches JSON using injected dependencies.
public struct APIService: Sendable {
    private let deps: AppDependencies

    /// Creates an API service with the given dependencies.
    ///
    /// - Parameter deps: The dependency container. Defaults to ``AppDependencies/live``.
    public init(deps: AppDependencies = .live) { self.deps = deps }

    /// Fetches and deserializes JSON from a URL.
    ///
    /// - Parameter url: The URL to fetch.
    /// - Returns: The deserialized JSON object.
    /// - Throws: Network errors or `JSONSerialization` errors.
    public func fetchJSON(from url: URL) async throws -> Any {
        deps.logger.log(.info, "GET \(url)")
        let (data, _) = try await deps.http.data(from: url)
        return try JSONSerialization.jsonObject(with: data)
    }
}
