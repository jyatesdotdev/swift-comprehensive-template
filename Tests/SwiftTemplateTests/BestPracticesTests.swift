import Testing
import Foundation
@testable import SwiftTemplate

// MARK: - Best Practices Tests

@Suite("BestPractices")
struct BestPracticesTests {

    @Test func point2DEquality() {
        #expect(Point2D(x: 1, y: 2) == Point2D(x: 1, y: 2))
        #expect(Point2D(x: 1, y: 2) != Point2D(x: 3, y: 4))
        #expect(Point2D() == Point2D(x: 0, y: 0))
    }

    @Test func cowBufferAppendAndCopy() {
        let a = COWBuffer([1, 2, 3])
        var b = a
        b[0] = 99
        #expect(a[0] == 1, "Original unchanged after COW copy")
        #expect(b[0] == 99)
        #expect(a.count == 3)
    }

    @Test func configRequire() throws {
        let config = Config(["host": "localhost", "port": "8080"])
        #expect(try config.require("host") == "localhost")
        #expect(try config.requireInt("port") == 8080)
    }

    @Test func configMissingKey() {
        let config = Config([:])
        #expect(throws: ConfigError.self) { try config.require("missing") }
    }

    @Test func configTypeMismatch() {
        let config = Config(["port": "abc"])
        #expect(throws: ConfigError.self) { try config.requireInt("port") }
    }

    @Test func clampedPropertyWrapper() {
        var settings = AudioSettings()
        #expect(settings.volume == 0.8)
        settings.volume = 1.5
        #expect(settings.volume == 1.0, "Clamps to upper bound")
        settings.volume = -0.5
        #expect(settings.volume == 0.0, "Clamps to lower bound")
        settings.pan = 0.5
        #expect(settings.pan == 0.5)
    }
}

// MARK: - Additional BestPractices Tests

@Suite("BestPracticesExtended")
struct BestPracticesExtendedTests {

    struct SteppablePoint: Steppable {
        var x: Double = 0
        mutating func step(dt: Double) { x += dt }
    }

    @Test func stepAll() {
        var items = [SteppablePoint(), SteppablePoint()]
        items.stepAll(dt: 1.0)
        #expect(items[0].x == 1.0)
        #expect(items[1].x == 1.0)
    }

    @Test func cowBufferAppend() {
        var buf = COWBuffer<Int>([1, 2])
        buf.append(3)
        #expect(buf.count == 3)
        #expect(buf[2] == 3)
    }

    @Test func cowBufferCopyOnWriteAppend() {
        let a = COWBuffer([1, 2])
        var b = a
        b.append(3)
        #expect(a.count == 2)
        #expect(b.count == 3)
    }

    @Test func configErrorCases() {
        let e1 = ConfigError.missingKey("k")
        let e2 = ConfigError.typeMismatch(key: "k", expected: "Int")
        let e3 = ConfigError.validationFailed("bad")
        #expect(e1 is Error)
        #expect(e2 is Error)
        #expect(e3 is Error)
    }
}

// MARK: - StateMachine Tests

@Suite("StateMachine")
struct StateMachineTests {

    enum DoorState { case open, closed, locked }
    enum DoorEvent { case open, close, lock, unlock }

    private func makeDoor() -> StateMachine<DoorState, DoorEvent> {
        StateMachine(initial: .closed, transitions: [
            .init(from: .closed, on: .open, to: .open),
            .init(from: .open, on: .close, to: .closed),
            .init(from: .closed, on: .lock, to: .locked),
            .init(from: .locked, on: .unlock, to: .closed)
        ])
    }

    @Test func allowedTransitionsAdvanceState() {
        var door = makeDoor()
        let opened = door.handle(.open)
        #expect(opened)
        #expect(door.state == .open)
        let closed = door.handle(.close)
        #expect(closed)
        #expect(door.state == .closed)
    }

    @Test func disallowedEventsAreIgnored() {
        var door = makeDoor()
        door.handle(.lock)
        let opened = door.handle(.open)
        #expect(!opened, "A locked door cannot open")
        #expect(door.state == .locked)
    }

    @Test func nextStatePreviewsWithoutMutating() {
        let door = makeDoor()
        #expect(door.nextState(for: .open) == .open)
        #expect(door.nextState(for: .unlock) == nil)
        #expect(door.state == .closed)
    }

    @Test func valueSemanticsSnapshotState() {
        var a = makeDoor()
        let b = a
        a.handle(.open)
        #expect(a.state == .open)
        #expect(b.state == .closed)
    }
}

// MARK: - Smoke Test

@Test func version() {
    #expect(SwiftTemplate.version == "0.1.0")
}
