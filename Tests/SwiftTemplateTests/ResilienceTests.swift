import Testing
import Foundation
@testable import SwiftTemplate

// MARK: - Resilience Tests

@Suite("Resilience")
struct ResilienceTests {

    struct StubError: Error, Equatable {}

    actor AttemptCounter {
        private(set) var count = 0
        func next() -> Int {
            count += 1
            return count
        }
    }

    @Test func timeoutReturnsFastResult() async throws {
        let value = try await Resilience.withTimeout(.seconds(5)) { 42 }
        #expect(value == 42)
    }

    @Test func timeoutThrowsOnSlowOperation() async {
        await #expect(throws: TimeoutError.self) {
            try await Resilience.withTimeout(.milliseconds(20)) {
                try await Task.sleep(for: .seconds(60))
                return 0
            }
        }
    }

    @Test func timeoutPropagatesOperationError() async {
        await #expect(throws: StubError.self) {
            try await Resilience.withTimeout(.seconds(5)) { () -> Int in
                throw StubError()
            }
        }
    }

    @Test func retrySucceedsAfterFailures() async throws {
        let counter = AttemptCounter()
        let result = try await Resilience.retry(maxAttempts: 5, baseDelay: .milliseconds(1)) {
            let attempt = await counter.next()
            if attempt < 3 { throw StubError() }
            return attempt
        }
        #expect(result == 3)
    }

    @Test func retryThrowsAfterExhaustingAttempts() async {
        let counter = AttemptCounter()
        await #expect(throws: StubError.self) {
            try await Resilience.retry(maxAttempts: 3, baseDelay: .milliseconds(1)) { () -> Int in
                _ = await counter.next()
                throw StubError()
            }
        }
        #expect(await counter.count == 3)
    }

    @Test func retryStopsOnNonRetryableError() async {
        let counter = AttemptCounter()
        await #expect(throws: StubError.self) {
            try await Resilience.retry(
                maxAttempts: 5,
                baseDelay: .milliseconds(1),
                shouldRetry: { _ in false },
                operation: { () -> Int in
                    _ = await counter.next()
                    throw StubError()
                }
            )
        }
        #expect(await counter.count == 1)
    }

    @Test func retrySingleAttemptRunsOnce() async throws {
        let counter = AttemptCounter()
        let result = try await Resilience.retry(maxAttempts: 1) {
            await counter.next()
        }
        #expect(result == 1)
    }
}
