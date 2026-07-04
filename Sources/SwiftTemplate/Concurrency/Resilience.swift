// MARK: - Resilience Primitives
// Timeouts and retries with exponential backoff for async operations.

import Foundation

/// Error thrown when ``Resilience/withTimeout(_:operation:)`` exceeds its deadline.
public struct TimeoutError: Error, Equatable, CustomStringConvertible {
    /// The duration that elapsed before the operation was abandoned.
    public let duration: Duration

    /// Creates a timeout error.
    ///
    /// - Parameter duration: The deadline that was exceeded.
    public init(duration: Duration) { self.duration = duration }

    public var description: String { "Operation timed out after \(duration)" }
}

/// Timeout and retry building blocks for unreliable async operations.
public enum Resilience {

    /// Runs an operation with a deadline, cancelling it on expiry.
    ///
    /// - Parameters:
    ///   - duration: The maximum time the operation may take.
    ///   - operation: The async work to race against the deadline.
    /// - Returns: The operation's result if it beats the deadline.
    /// - Throws: ``TimeoutError`` on expiry, or the operation's own error.
    public static func withTimeout<R: Sendable>(
        _ duration: Duration,
        operation: @Sendable @escaping () async throws -> R
    ) async throws -> R {
        try await withThrowingTaskGroup(of: R.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: duration)
                throw TimeoutError(duration: duration)
            }
            guard let first = try await group.next() else {
                throw CancellationError()
            }
            group.cancelAll()
            return first
        }
    }

    /// Retries an operation with exponential backoff and full jitter.
    ///
    /// Waits `baseDelay * 2^attempt` (capped at `maxDelay`, scaled by a random
    /// 0–1 jitter factor) between attempts. Cancellation is never retried and
    /// propagates immediately.
    ///
    /// - Parameters:
    ///   - maxAttempts: Total attempts including the first. Must be ≥ 1.
    ///   - baseDelay: Backoff for the first retry. Defaults to 100 ms.
    ///   - maxDelay: Upper bound for any single backoff. Defaults to 5 s.
    ///   - shouldRetry: Inspects the error; return `false` to give up early.
    ///     Defaults to retrying every error.
    ///   - operation: The async work to attempt.
    /// - Returns: The first successful result.
    /// - Throws: The final attempt's error, the first non-retryable error, or
    ///   `CancellationError`.
    public static func retry<R: Sendable>(
        maxAttempts: Int = 3,
        baseDelay: Duration = .milliseconds(100),
        maxDelay: Duration = .seconds(5),
        shouldRetry: @Sendable (any Error) -> Bool = { _ in true },
        operation: @Sendable @escaping () async throws -> R
    ) async throws -> R {
        precondition(maxAttempts >= 1, "maxAttempts must be at least 1")
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                let isLastAttempt = attempt + 1 == maxAttempts
                if isLastAttempt || !shouldRetry(error) { throw error }
                let exponential = baseDelay * (1 << min(attempt, 30))
                let capped = min(exponential, maxDelay)
                let jittered = capped * Double.random(in: 0...1)
                try await Task.sleep(for: jittered)
            }
        }
        // Unreachable: the final iteration always returns or throws.
        throw CancellationError()
    }
}
