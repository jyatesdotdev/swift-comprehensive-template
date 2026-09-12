// SwiftTemplateUIDemo — launches a macOS window showcasing SwiftTemplateUI.
// Run with: swift run SwiftTemplateUIDemo

#if os(macOS) && canImport(SwiftUI)
import SwiftTemplate
import SwiftTemplateUI
import SwiftUI

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup("SwiftTemplate UI Demo") {
            DemoRootView()
                .frame(minWidth: 640, minHeight: 480)
        }
    }
}

struct DemoRootView: View {
    var body: some View {
        TabView {
            ComponentsDemo()
                .tabItem { Label("Components", systemImage: "square.grid.2x2") }
            GameCanvasView(scene: BouncingBallScene())
                .tabItem { Label("Game", systemImage: "gamecontroller") }
            MetalViewport()
                .tabItem { Label("Metal", systemImage: "cpu") }
        }
        .padding()
    }
}

/// Demonstrates ItemListViewModel + AsyncContentView + the component library.
struct ComponentsDemo: View {
    @State private var loadGeneration = 0
    @State private var viewModel = ItemListViewModel {
        // Simulated data source latency so the loading phase is visible.
        try await Task.sleep(for: .milliseconds(600))
        return ["Concurrency", "Rendering", "Systems", "HPC", "Simulation", "CrossPlatform"]
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(alignment: .leading, spacing: 12) {
            TextField("Filter modules…", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)
            AsyncContentView(state: viewModel.state) { _ in
                List(viewModel.filteredItems, id: \.self) { item in
                    Text(item)
                }
            }
            HStack {
                Button("Reload") {
                    loadGeneration += 1
                }
                .buttonStyle(.primary)
                if viewModel.state.isLoading {
                    ProgressView().controlSize(.small)
                }
            }
        }
        .card()
        .padding()
        .task(id: loadGeneration) { await viewModel.load() }
    }
}
#else
@main
struct DemoApp {
    static func main() {
        print("SwiftTemplateUIDemo requires macOS with SwiftUI.")
    }
}
#endif
