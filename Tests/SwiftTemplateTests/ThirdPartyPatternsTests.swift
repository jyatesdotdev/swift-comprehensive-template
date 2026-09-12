import Testing
import Foundation
@testable import SwiftTemplate
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - ThirdPartyPatterns Tests

@Suite("ThirdPartyPatterns")
struct ThirdPartyPatternsTests {

    struct Payload: Codable, Equatable {
        let key: String
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

    private func service(mock: MockHTTPClient) -> APIService {
        APIService(deps: AppDependencies(http: mock, logger: PrintLogger()))
    }

    @Test func apiServiceFetchJSON() async throws {
        let mock = MockHTTPClient.returning(Data("{\"key\":\"value\"}".utf8))
        let url = try #require(URL(string: "https://example.com"))
        let result = try await service(mock: mock).fetchJSON(from: url)
        let dict = result as? [String: Any]
        #expect(dict?["key"] as? String == "value")
    }

    @Test func typedFetchDecodes() async throws {
        let mock = MockHTTPClient.returning(Data("{\"key\":\"value\"}".utf8))
        let url = try #require(URL(string: "https://example.com"))
        let payload: Payload = try await service(mock: mock).fetch(from: url)
        #expect(payload == Payload(key: "value"))
    }

    @Test func fetchJSONThrowsOnBadStatus() async throws {
        let mock = MockHTTPClient.returning(Data("{}".utf8), statusCode: 500)
        let url = try #require(URL(string: "https://example.com"))
        await #expect(throws: APIError.badStatus(500)) {
            _ = try await service(mock: mock).fetchJSON(from: url)
        }
    }

    @Test func typedFetchThrowsOnBadStatus() async throws {
        let mock = MockHTTPClient.returning(Data(), statusCode: 500)
        let url = try #require(URL(string: "https://example.com"))
        await #expect(throws: APIError.badStatus(500)) {
            let _: Payload = try await service(mock: mock).fetch(from: url)
        }
    }

    @Test func typedFetchThrowsOnMalformedBody() async throws {
        let mock = MockHTTPClient.returning(Data("not json".utf8))
        let url = try #require(URL(string: "https://example.com"))
        await #expect(throws: APIError.self) {
            let _: Payload = try await service(mock: mock).fetch(from: url)
        }
    }

    @Test func mockClientCustomHandler() async throws {
        let mock = MockHTTPClient { url in
            (Data(url.absoluteString.utf8), URLResponse(
                url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil
            ))
        }
        let url = try #require(URL(string: "https://example.com/echo"))
        let (data, _) = try await mock.data(from: url)
        #expect(String(decoding: data, as: UTF8.self) == "https://example.com/echo")
    }
}
