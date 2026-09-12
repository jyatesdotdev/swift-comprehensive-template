// MARK: - Observation & MVVM Patterns
// @Observable view models, state-driven UI, and injected async loading.

#if canImport(SwiftUI)
import Foundation
import Observation

// MARK: - 1. Load State

/// The lifecycle of asynchronously loaded content.
///
/// Drive views from a single `LoadState` value instead of separate
/// `isLoading` / `error` / `items` properties — the compiler then guarantees
/// the UI can only show one of the four phases at a time.
public enum LoadState<Value: Sendable>: Sendable {
    /// Nothing has been requested yet.
    case idle
    /// A load is in flight.
    case loading
    /// The load finished successfully.
    case loaded(Value)
    /// The load failed with a user-presentable message.
    case failed(String)

    /// The loaded value, or `nil` in any other phase.
    public var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    /// The failure message, or `nil` in any other phase.
    public var errorMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }

    /// `true` while a load is in flight.
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

extension LoadState: Equatable where Value: Equatable {}

// MARK: - 2. Observable View Model

/// A list-with-search view model demonstrating `@Observable` MVVM.
///
/// The loader is injected, so tests exercise every state transition without
/// networking or timers:
///
/// ```swift
/// let viewModel = ItemListViewModel { ["a", "b"] }
/// await viewModel.load()
/// #expect(viewModel.state.value == ["a", "b"])
/// ```
@MainActor
@Observable
public final class ItemListViewModel {
    /// The current phase of the item load.
    public private(set) var state: LoadState<[String]> = .idle

    /// Case-insensitive filter applied to the loaded items.
    public var query: String = ""

    @ObservationIgnored
    private let loadItems: @Sendable () async throws -> [String]

    /// Creates a view model with an injected asynchronous loader.
    ///
    /// - Parameter loadItems: Produces the items. Production code passes a
    ///   real data source; tests pass a stub.
    public init(loadItems: @escaping @Sendable () async throws -> [String]) {
        self.loadItems = loadItems
    }

    /// The loaded items filtered by ``query`` (all items when the query is empty).
    public var filteredItems: [String] {
        guard let items = state.value else { return [] }
        guard !query.isEmpty else { return items }
        return items.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    /// Runs the loader, transitioning through ``LoadState`` phases.
    ///
    /// ``CancellationError`` is not a load failure: a cancelled in-flight
    /// reload must not overwrite a newer ``LoadState/loaded(_:)`` (or leave
    /// a stale ``LoadState/failed(_:)``) when SwiftUI replaces `.task(id:)`.
    public func load() async {
        state = .loading
        do {
            state = .loaded(try await loadItems())
        } catch is CancellationError {
            return
        } catch {
            state = .failed(String(describing: error))
        }
    }
}
#endif
