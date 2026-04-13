#if canImport(Testing)
import Testing
import Foundation
@testable import SwiftTemplate

// MARK: - ThirdPartyPatterns Tests

@Suite("ThirdPartyPatterns")
struct ThirdPartyPatternsTests {

    struct MockHTTPClient: HTTPClient, Sendable {
        let responseData: Data
        func data(from url: URL) async throws -> (Data, URLResponse) {
            (responseData, URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
        }
    }

    @Test func printLogger() {
        let logger = PrintLogger()
        logger.log(.debug, "test debug")
        logger.log(.info, "test info")
        logger.log(.warning, "test warning")
        logger.log(.error, "test error")
    }

    @Test func logLevelRawValues() {
        #expect(LogLevel.debug.rawValue == "debug")
        #expect(LogLevel.error.rawValue == "error")
    }

    @Test func appDependenciesLive() {
        let deps = AppDependencies.live
        #expect(deps.logger is PrintLogger)
    }

    @Test func apiServiceFetchJSON() async throws {
        let json = Data("{\"key\":\"value\"}".utf8)
        let mock = MockHTTPClient(responseData: json)
        let deps = AppDependencies(http: mock, logger: PrintLogger())
        let service = APIService(deps: deps)
        let url = try #require(URL(string: "https://example.com"))
        let result = try await service.fetchJSON(from: url)
        let dict = result as? [String: Any]
        #expect(dict?["key"] as? String == "value")
    }
}
#endif
