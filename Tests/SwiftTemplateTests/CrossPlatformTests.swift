import Testing
import Foundation
@testable import SwiftTemplate

// MARK: - CrossPlatform Tests

@Suite("CrossPlatform")
struct CrossPlatformTests {

    @Test func platformCurrent() {
        #if os(macOS)
        #expect(Platform.current == .macOS)
        #elseif os(Linux)
        #expect(Platform.current == .linux)
        #else
        #expect(Platform.current != .unknown)
        #endif
    }

    @Test func platformIsApple() {
        #if canImport(Darwin)
        #expect(Platform.isApple)
        #else
        #expect(!Platform.isApple)
        #endif
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
        if case .badStatus(let code) = e1 {
            #expect(code == 404)
        } else {
            #expect(Bool(false), "expected badStatus")
        }
        if case .noData = e2 {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "expected noData")
        }
    }
}
