#if canImport(Testing)
import Testing
import Foundation
@testable import SwiftTemplate

// MARK: - CrossPlatform Tests

@Suite("CrossPlatform")
struct CrossPlatformTests {

    @Test func platformCurrent() {
        #expect(Platform.current == .macOS)
    }

    @Test func platformIsApple() {
        #expect(Platform.isApple == true)
    }

    @Test func platformArchitecture() {
        let arch = Platform.architecture
        #expect(arch == "arm64" || arch == "x86_64")
    }

    @Test func portablePathHome() {
        #expect(!PortablePath.home.isEmpty)
    }

    @Test func portablePathTemp() {
        #expect(!PortablePath.temp.isEmpty)
    }

    @Test func portablePathJoin() {
        #expect(PortablePath.join("a", "b", "c") == "a/b/c")
    }

    @Test func platformLoggerLevels() {
        PlatformLogger.log(.debug, "d")
        PlatformLogger.log(.info, "i")
        PlatformLogger.log(.warning, "w")
        PlatformLogger.log(.error, "e")
    }

    @Test func featureFlags() {
        _ = FeatureFlags.hasGPU
        _ = FeatureFlags.hasSwiftUI
        _ = FeatureFlags.hasCombine
    }

    @Test func byteOrderIsLittleEndian() {
        #expect(ByteOrder.isLittleEndian == true)
    }

    @Test func byteOrderRoundTrip() {
        let value: UInt32 = 0xDEADBEEF
        let bytes = ByteOrder.toBigEndian(value)
        #expect(bytes.count == 4)
        let decoded = ByteOrder.fromBigEndian(bytes)
        #expect(decoded == value)
    }

    @Test func byteOrderFromBigEndianTooShort() {
        #expect(ByteOrder.fromBigEndian([1, 2]) == nil)
    }

    @Test func compileDiagnosticsLegacyFetch() {
        CompileDiagnostics.legacyFetch()
    }

    @Test func httpErrorCases() {
        let e1 = PortableHTTP.HTTPError.badStatus(404)
        let e2 = PortableHTTP.HTTPError.noData
        #expect(e1 is Error)
        #expect(e2 is Error)
    }
}
#endif
