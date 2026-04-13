import Testing
import Foundation
@testable import SwiftTemplate

// MARK: - Systems Tests

@Suite("Systems")
struct SystemsTests {

    @Test func fileSystemWriteReadDelete() throws {
        let tmp = PortablePath.join(PortablePath.temp, "swift-test-\(UUID().uuidString).txt")
        let data = Data("hello".utf8)
        try FileSystem.write(data, to: tmp)
        let read = try FileSystem.readData(at: tmp)
        #expect(read == data)
        let str = try FileSystem.readString(at: tmp)
        #expect(str == "hello")
        try FileManager.default.removeItem(atPath: tmp)
    }

    @Test func fileSystemNotFound() {
        #expect(throws: FileSystem.FSError.self) {
            try FileSystem.readData(at: "/nonexistent-\(UUID().uuidString)")
        }
    }

    @Test func fileSystemListDirectory() throws {
        let entries = try FileSystem.listDirectory(at: PortablePath.temp)
        #expect(entries is [String])
    }

    @Test func fileSystemWalk() throws {
        let dir = PortablePath.join(PortablePath.temp, "swift-walk-\(UUID().uuidString)")
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let file = PortablePath.join(dir, "a.txt")
        try Data("x".utf8).write(to: URL(fileURLWithPath: file))
        let paths = try FileSystem.walk(dir)
        #expect(paths.contains("a.txt"))
        try FileManager.default.removeItem(atPath: dir)
    }

    @Test func fileSystemWalkNotFound() {
        #expect(throws: FileSystem.FSError.self) {
            try FileSystem.walk("/nonexistent-\(UUID().uuidString)")
        }
    }

    @Test func fileSystemAttributes() throws {
        let tmp = PortablePath.join(PortablePath.temp, "swift-attr-\(UUID().uuidString).txt")
        try FileSystem.write(Data("x".utf8), to: tmp)
        let attrs = try FileSystem.attributes(at: tmp)
        #expect(attrs[.size] != nil)
        try FileManager.default.removeItem(atPath: tmp)
    }

    @Test func fileSystemAtomicWrite() throws {
        let tmp = PortablePath.join(PortablePath.temp, "swift-atomic-\(UUID().uuidString).txt")
        try FileSystem.atomicWrite(Data("atomic".utf8), to: tmp)
        let str = try FileSystem.readString(at: tmp)
        #expect(str == "atomic")
        try FileSystem.atomicWrite(Data("v2".utf8), to: tmp)
        #expect(try FileSystem.readString(at: tmp) == "v2")
        try FileManager.default.removeItem(atPath: tmp)
    }

    @Test func fsErrorDescriptions() {
        let e1 = FileSystem.FSError.notFound("/x")
        let e2 = FileSystem.FSError.alreadyExists("/x")
        let e3 = FileSystem.FSError.permissionDenied("/x")
        let e4 = FileSystem.FSError.ioError("/x", underlying: NSError(domain: "", code: 0))
        #expect(e1.description.contains("Not found"))
        #expect(e2.description.contains("Already exists"))
        #expect(e3.description.contains("Permission denied"))
        #expect(e4.description.contains("I/O error"))
    }

    @Test func systemEnvironment() {
        #expect(SystemEnvironment.get("PATH") != nil)
        #expect(!SystemEnvironment.all.isEmpty)
        #expect(!SystemEnvironment.hostName.isEmpty)
        #expect(!SystemEnvironment.osVersion.isEmpty)
        #expect(SystemEnvironment.physicalMemory > 0)
        #expect(SystemEnvironment.processorCount > 0)
    }

    @Test func shellRun() {
        let result = Shell.run("/bin/echo", arguments: ["hello"])
        #expect(result.succeeded)
        #expect(result.stdout.contains("hello"))
        #expect(result.exitCode == 0)
    }

    @Test func shellSh() {
        let result = Shell.sh("echo test")
        #expect(result.succeeded)
        #expect(result.stdout.contains("test"))
    }

    @Test func shellRunAsync() async {
        let result = await Shell.runAsync("/bin/echo", arguments: ["async"])
        #expect(result.succeeded)
        #expect(result.stdout.contains("async"))
    }

    @Test func shellRunFailure() {
        let result = Shell.run("/bin/sh", arguments: ["-c", "exit 1"])
        #expect(!result.succeeded)
        #expect(result.exitCode == 1)
    }

    @Test func streamIOReadChunked() throws {
        let tmp = PortablePath.join(PortablePath.temp, "swift-chunk-\(UUID().uuidString).txt")
        try FileSystem.write(Data("abcdef".utf8), to: tmp)
        var chunks: [Data] = []
        try StreamIO.readChunked(path: tmp, chunkSize: 3) { chunks.append($0) }
        #expect(!chunks.isEmpty)
        try FileManager.default.removeItem(atPath: tmp)
    }

    @Test func streamIOReadChunkedNotFound() {
        #expect(throws: FileSystem.FSError.self) {
            try StreamIO.readChunked(path: "/nonexistent-\(UUID().uuidString)") { _ in }
        }
    }

    @Test func streamIOMakePipe() {
        let (read, write) = StreamIO.makePipe()
        write.write(Data("pipe".utf8))
        write.closeFile()
        let data = read.readDataToEndOfFile()
        #expect(String(decoding: data, as: UTF8.self) == "pipe")
    }

    @Test func unsafeMemoryWithManualBuffer() {
        var sum = 0
        UnsafeMemory.withManualBuffer(of: Int.self, count: 4) { buf in
            for i in 0..<4 { buf[i] = i }
            sum = buf.reduce(0, +)
        }
        #expect(sum == 6)
    }

    @Test func unsafeMemoryReinterpret() {
        let floats: [Float] = [1.0, 2.0]
        let bytes = UnsafeMemory.reinterpret(floats, as: UInt8.self)
        #expect(bytes.count == 8)
    }

    @Test func unsafeMemoryCopyBytes() {
        let src: [UInt8] = [1, 2, 3, 4]
        var dst = [UInt8](repeating: 0, count: 4)
        src.withUnsafeBytes { srcPtr in
            dst.withUnsafeMutableBytes { dstPtr in
                guard let srcBase = srcPtr.baseAddress,
                      let dstBase = dstPtr.baseAddress else { return }
                UnsafeMemory.copyBytes(from: srcBase, to: dstBase, count: 4)
            }
        }
        #expect(dst == [1, 2, 3, 4])
    }

    @Test func cfBridgingStringRoundTrip() {
        #expect(CFBridging.cfStringRoundTrip("hello") == "hello")
    }

    @Test func cfBridgingDictionary() {
        let dict = CFBridging.cfDictionaryExample()
        #expect(dict["key"] as? String == "value")
        #expect(dict["number"] as? Int == 42)
    }

    @Test func signalHandling() {
        Signals.ignore(SIGUSR1)
        Signals.restore(SIGUSR1)
    }
}
