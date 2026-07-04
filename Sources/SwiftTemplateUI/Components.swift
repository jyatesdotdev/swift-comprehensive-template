// MARK: - Reusable SwiftUI Components
// View modifiers, button styles, and state-driven container views.

#if canImport(SwiftUI)
import SwiftUI

// MARK: - 1. View Modifier

/// Wraps content in a padded, rounded "card" with a subtle shadow.
public struct CardModifier: ViewModifier {
    /// Creates a card modifier.
    public init() {}

    /// Applies the card chrome around `content`.
    ///
    /// - Parameter content: The view being modified.
    public func body(content: Content) -> some View {
        content
            .padding()
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2, y: 1)
    }
}

extension View {
    /// Wraps the view in card chrome — see ``CardModifier``.
    public func card() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - 2. Button Style

/// A filled capsule button style for primary actions.
public struct PrimaryButtonStyle: ButtonStyle {
    /// Creates the style.
    public init() {}

    /// Builds the styled button body.
    ///
    /// - Parameter configuration: The button's label and pressed state.
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Color.accentColor.opacity(configuration.isPressed ? 0.7 : 1),
                in: Capsule()
            )
            .foregroundStyle(.white)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Shorthand for ``PrimaryButtonStyle``: `.buttonStyle(.primary)`.
    public static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

// MARK: - 3. State-Driven Container

/// Renders a ``LoadState`` — spinner while loading, error with optional
/// retry on failure, and your content when loaded.
///
/// ```swift
/// AsyncContentView(state: viewModel.state) { items in
///     List(items, id: \.self) { Text($0) }
/// }
/// ```
public struct AsyncContentView<Value: Sendable, Content: View>: View {
    private let state: LoadState<Value>
    private let retryAction: (() -> Void)?
    private let content: (Value) -> Content

    /// Creates a state-driven container.
    ///
    /// - Parameters:
    ///   - state: The load state to render.
    ///   - retryAction: Shown as a Retry button in the failed phase. Optional.
    ///   - content: Builds the success view from the loaded value.
    public init(
        state: LoadState<Value>,
        retryAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.retryAction = retryAction
        self.content = content
    }

    /// The phase-appropriate view.
    public var body: some View {
        switch state {
        case .idle:
            Color.clear
        case .loading:
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(message)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let retryAction {
                    Button("Retry", action: retryAction)
                        .buttonStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let value):
            content(value)
        }
    }
}
#endif
