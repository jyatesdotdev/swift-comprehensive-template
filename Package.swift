// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftTemplate",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "SwiftTemplate", targets: ["SwiftTemplate"]),
        .executable(name: "SwiftTemplateExample", targets: ["SwiftTemplateExample"]),
        .executable(name: "SwiftTemplateCLI", targets: ["SwiftTemplateCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.58.0"),
    ],
    targets: [
        .target(
            name: "SwiftTemplate",
            path: "Sources/SwiftTemplate",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .executableTarget(
            name: "SwiftTemplateCLI",
            dependencies: [
                "SwiftTemplate",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/SwiftTemplateCLI"
        ),
        .executableTarget(
            name: "SwiftTemplateExample",
            dependencies: ["SwiftTemplate"],
            path: "Sources/SwiftTemplateExample"
        ),
        .testTarget(
            name: "SwiftTemplateTests",
            dependencies: ["SwiftTemplate"],
            path: "Tests/SwiftTemplateTests"
        ),
        .testTarget(
            name: "SwiftTemplateCLITests",
            dependencies: ["SwiftTemplateCLI"],
            path: "Tests/SwiftTemplateCLITests"
        )
    ]
)
