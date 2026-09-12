#if canImport(Testing) && canImport(SwiftUI)
import Testing
import Foundation
@testable import SwiftTemplate
@testable import SwiftTemplateUI

// MARK: - LoadState Tests

@Suite("LoadState")
struct LoadStateTests {

    @Test func loadedExposesValue() {
        let state = LoadState<Int>.loaded(42)
        #expect(state.value == 42)
        #expect(state.errorMessage == nil)
        #expect(state.isLoading == false)
    }

    @Test func failedExposesMessage() {
        let state = LoadState<Int>.failed("boom")
        #expect(state.value == nil)
        #expect(state.errorMessage == "boom")
    }

    @Test(arguments: [LoadState<Int>.idle, .loading, .failed("x")])
    func nonLoadedStatesHaveNoValue(state: LoadState<Int>) {
        #expect(state.value == nil)
    }

    @Test func onlyLoadingIsLoading() {
        #expect(LoadState<Int>.loading.isLoading)
        #expect(!LoadState<Int>.idle.isLoading)
        #expect(!LoadState<Int>.loaded(1).isLoading)
        #expect(!LoadState<Int>.failed("x").isLoading)
    }
}

// MARK: - ItemListViewModel Tests

@MainActor
@Suite("ItemListViewModel")
struct ItemListViewModelTests {

    @Test func startsIdle() {
        let viewModel = ItemListViewModel { [] }
        #expect(viewModel.state == .idle)
        #expect(viewModel.filteredItems.isEmpty)
    }

    @Test func loadSuccessTransitionsToLoaded() async {
        let viewModel = ItemListViewModel { ["alpha", "beta"] }
        await viewModel.load()
        #expect(viewModel.state == .loaded(["alpha", "beta"]))
    }

    @Test func loadFailureTransitionsToFailed() async {
        struct StubError: Error {}
        let viewModel = ItemListViewModel { throw StubError() }
        await viewModel.load()
        #expect(viewModel.state.errorMessage != nil)
    }

    @Test func loadCancellationDoesNotFail() async {
        let viewModel = ItemListViewModel {
            try await Task.sleep(for: .seconds(60))
            return ["x"]
        }
        let task = Task { await viewModel.load() }
        task.cancel()
        _ = await task.result
        #expect(viewModel.state.errorMessage == nil)
    }

    @Test func queryFiltersCaseInsensitively() async {
        let viewModel = ItemListViewModel { ["Alpha", "Beta", "Gamma"] }
        await viewModel.load()
        viewModel.query = "aLpH"
        #expect(viewModel.filteredItems == ["Alpha"])
        viewModel.query = ""
        #expect(viewModel.filteredItems == ["Alpha", "Beta", "Gamma"])
    }
}

// MARK: - PixelBuffer Image Bridge Tests

#if canImport(CoreGraphics)
@Suite("PixelBufferImage")
struct PixelBufferImageTests {

    @Test func makeCGImageDimensions() {
        let buffer = PixelBuffer(width: 4, height: 3, fill: Color4(r: 1, g: 0, b: 0))
        let image = buffer.makeCGImage()
        #expect(image?.width == 4)
        #expect(image?.height == 3)
        #expect(image?.bitsPerPixel == 32)
    }

    @Test func componentClampingSurvivesOutOfRangeColors() {
        var buffer = PixelBuffer(width: 1, height: 1)
        buffer[0, 0] = Color4(r: 2.0, g: -1.0, b: 0.5, a: 1)
        #expect(buffer.makeCGImage() != nil)
    }
}

// MARK: - BouncingBallScene Tests

@Suite("BouncingBallScene")
struct BouncingBallSceneTests {

    @Test func updateAdvancesSimulation() {
        let scene = BouncingBallScene(particleCount: 3)
        var before = PixelBuffer(width: 32, height: 24)
        scene.render(into: &before)
        for _ in 0..<30 { scene.update(dt: 1.0 / 60.0) }
        var after = PixelBuffer(width: 32, height: 24)
        scene.render(into: &after)
        #expect(before.pixels != after.pixels)
    }

    @Test func renderDrawsParticles() {
        let scene = BouncingBallScene(particleCount: 5)
        var buffer = PixelBuffer(width: 64, height: 48)
        scene.render(into: &buffer)
        let litPixels = buffer.pixels.filter { $0.r > 0.5 }
        #expect(!litPixels.isEmpty)
    }
}
#endif
#endif
