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

// MARK: - Mock Client for Tests

/// An ``HTTPClient`` backed by a closure — inject canned responses in tests.
public struct MockHTTPClient: HTTPClient {
    private let handler: @Sendable (URL) async throws -> (Data, URLResponse)

    /// Creates a mock client.
    ///
    /// - Parameter handler: Produces the response for each requested URL.
    public init(handler: @escaping @Sendable (URL) async throws -> (Data, URLResponse)) {
        self.handler = handler
    }

    /// Returns the canned response from the handler.
    ///
    /// - Parameter url: The URL being requested.
    /// - Returns: The handler's data and response.
    /// - Throws: Whatever the handler throws.
    public func data(from url: URL) async throws -> (Data, URLResponse) {
        try await handler(url)
    }

    /// A mock that answers every request with the given body and status code.
    ///
    /// - Parameters:
    ///   - body: The response body.
    ///   - statusCode: The HTTP status. Defaults to `200`.
    /// - Returns: A configured mock client.
    public static func returning(_ body: Data, statusCode: Int = 200) -> MockHTTPClient {
        MockHTTPClient { url in
            guard let response = HTTPURLResponse(
                url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil
            ) else {
                throw URLError(.badServerResponse)
            }
            return (body, response)
        }
    }
}

// MARK: - Dependency Container

/// Lightweight dependency container — swap `.live` for mocks in tests.
public struct AppDependencies: Sendable {
    /// The HTTP client used for network requests.
    public var http: any HTTPClient
    /// The logger used for diagnostic output.
    public var logger: any Logger

    /// Creates a dependency container.
    ///
    /// - Parameters:
    ///   - http: The HTTP client to use.
    ///   - logger: The logger to use.
    public init(http: any HTTPClient, logger: any Logger) {
        self.http = http
        self.logger = logger
    }

    /// Production dependencies using URLSession and print logging.
    public static let live = AppDependencies(
        http: URLSession.shared,
        logger: PrintLogger()
    )
}

// MARK: - Service Using Abstractions

/// Errors from typed API fetching.
public enum APIError: Error, Equatable {
    /// The server returned a non-2xx status code.
    case badStatus(Int)
    /// The body could not be decoded into the requested type.
    case decodingFailed(String)
}

/// A service that fetches JSON using injected dependencies.
public struct APIService: Sendable {
    private let deps: AppDependencies

    /// Creates an API service with the given dependencies.
    ///
    /// - Parameter deps: The dependency container. Defaults to ``AppDependencies/live``.
    public init(deps: AppDependencies = .live) { self.deps = deps }

    /// Fetches JSON from a URL and decodes it into a `Decodable` type.
    ///
    /// - Parameters:
    ///   - type: The type to decode. Usually inferred from context.
    ///   - url: The URL to fetch.
    /// - Returns: The decoded value.
    /// - Throws: ``APIError/badStatus(_:)`` on non-2xx responses,
    ///   ``APIError/decodingFailed(_:)`` on malformed bodies, or network errors.
    public func fetch<T: Decodable & Sendable>(_ type: T.Type = T.self, from url: URL) async throws -> T {
        deps.logger.log(.info, "GET \(url)")
        let (data, response) = try await deps.http.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.badStatus(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(String(describing: error))
        }
    }

    /// Fetches and deserializes untyped JSON — the escape hatch when no
    /// `Decodable` model exists. Prefer ``fetch(_:from:)``.
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
