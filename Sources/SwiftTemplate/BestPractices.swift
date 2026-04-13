// Best Practices — Compilable examples of Swift idioms.
//
// Demonstrates protocol-oriented design, value types with copy-on-write,
// typed error handling, and property wrappers.

// MARK: - Protocol-Oriented Design

/// A type that can be stepped forward in time.
public protocol Steppable {
    /// Advance the receiver by a time increment.
    ///
    /// - Parameter dt: The time delta in seconds.
    mutating func step(dt: Double)
}

/// A type that can report its energy.
public protocol EnergyReporting {
    /// The kinetic energy of the receiver in joules.
    var kineticEnergy: Double { get }
}

/// Default implementation for collections of steppable items.
extension Array where Element: Steppable {
    /// Step every element in the array forward by `dt`.
    ///
    /// - Parameter dt: The time delta in seconds.
    public mutating func stepAll(dt: Double) {
        for i in indices { self[i].step(dt: dt) }
    }
}

// MARK: - Value Types & Copy-on-Write

/// A 2D point — simple value type.
public struct Point2D: Sendable, Equatable {
    /// The x-coordinate.
    public var x: Double
    /// The y-coordinate.
    public var y: Double

    /// Creates a point with the given coordinates.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate. Defaults to `0`.
    ///   - y: The y-coordinate. Defaults to `0`.
    public init(x: Double = 0, y: Double = 0) { self.x = x; self.y = y }
}

/// A buffer with copy-on-write semantics.
public struct COWBuffer<Element> {
    private final class Storage {
        var elements: [Element]
        init(_ elements: [Element]) { self.elements = elements }
        func copy() -> Storage { Storage(elements) }
    }

    private var storage: Storage

    /// Creates a buffer backed by the given elements.
    ///
    /// - Parameter elements: The initial elements. Defaults to an empty array.
    public init(_ elements: [Element] = []) { storage = Storage(elements) }

    /// The number of elements in the buffer.
    public var count: Int { storage.elements.count }

    /// Accesses the element at `index`, triggering a copy-on-write if needed.
    ///
    /// - Parameter index: A valid index into the buffer.
    public subscript(index: Int) -> Element {
        get { storage.elements[index] }
        set {
            if !isKnownUniquelyReferenced(&storage) { storage = storage.copy() }
            storage.elements[index] = newValue
        }
    }

    /// Appends an element, triggering a copy-on-write if needed.
    ///
    /// - Parameter element: The element to append.
    public mutating func append(_ element: Element) {
        if !isKnownUniquelyReferenced(&storage) { storage = storage.copy() }
        storage.elements.append(element)
    }
}

// MARK: - Typed Error Handling

/// Errors from configuration parsing.
public enum ConfigError: Error {
    /// The requested key was not found.
    case missingKey(String)
    /// The value for the key could not be converted to the expected type.
    case typeMismatch(key: String, expected: String)
    /// A validation rule failed.
    case validationFailed(String)
}

/// A minimal configuration container demonstrating typed throws.
public struct Config: Sendable {
    private let values: [String: String]

    /// Creates a configuration from a dictionary of string key-value pairs.
    ///
    /// - Parameter values: The backing dictionary.
    public init(_ values: [String: String]) { self.values = values }

    /// Returns the value for `key`, or throws if missing.
    ///
    /// - Parameter key: The configuration key to look up.
    /// - Returns: The string value associated with `key`.
    /// - Throws: ``ConfigError/missingKey(_:)`` if the key is absent.
    public func require(_ key: String) throws -> String {
        guard let value = values[key] else { throw ConfigError.missingKey(key) }
        return value
    }

    /// Returns the integer value for `key`, or throws on missing/invalid data.
    ///
    /// - Parameter key: The configuration key to look up.
    /// - Returns: The integer value associated with `key`.
    /// - Throws: ``ConfigError/missingKey(_:)`` or ``ConfigError/typeMismatch(key:expected:)``.
    public func requireInt(_ key: String) throws -> Int {
        let raw = try require(key)
        guard let value = Int(raw) else { throw ConfigError.typeMismatch(key: key, expected: "Int") }
        return value
    }
}

// MARK: - Property Wrapper

/// Clamps a comparable value to a closed range.
@propertyWrapper
public struct Clamped<Value: Comparable> {
    private var value: Value

    /// The allowed range for the wrapped value.
    public let range: ClosedRange<Value>

    /// The clamped value. Setting a value outside the range pins it to the nearest bound.
    public var wrappedValue: Value {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }

    /// Creates a clamped property wrapper.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value (clamped to `range`).
    ///   - range: The closed range to clamp within.
    public init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}

/// Example usage of Clamped property wrapper.
public struct AudioSettings {
    /// Volume level, clamped to 0.0–1.0.
    @Clamped(0.0...1.0) public var volume: Double = 0.8
    /// Stereo pan, clamped to -1.0–1.0.
    @Clamped(-1.0...1.0) public var pan: Double = 0.0

    /// Creates audio settings with default values.
    public init() {}
}
