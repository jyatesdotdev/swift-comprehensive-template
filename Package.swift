// swift-tools-version: 5.9

import PackageDescription

#if os(macOS)
let swiftTemplatePlugins: [Target.PluginUsage] = [
    .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
]
#else
let swiftTemplatePlugins: [Target.PluginUsage] = []
#endif

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
        .library(name: "SwiftTemplateUI", targets: ["SwiftTemplateUI"]),
        .executable(name: "SwiftTemplateExample", targets: ["SwiftTemplateExample"]),
        .executable(name: "SwiftTemplateCLI", targets: ["SwiftTemplateCLI"]),
        .executable(name: "SwiftTemplateUIDemo", targets: ["SwiftTemplateUIDemo"])
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
            exclude: [
                "AGENTS.md",
                "Concurrency/AGENTS.md",
                "HPC/AGENTS.md",
                "Rendering/AGENTS.md",
                "Simulation/AGENTS.md",
                "Systems/AGENTS.md"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ],
            plugins: swiftTemplatePlugins
        ),
        .target(
            name: "SwiftTemplateUI",
            dependencies: ["SwiftTemplate"],
            path: "Sources/SwiftTemplateUI",
            exclude: ["AGENTS.md"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ],
            plugins: swiftTemplatePlugins
        ),
        .executableTarget(
            name: "SwiftTemplateUIDemo",
            dependencies: ["SwiftTemplateUI"],
            path: "Sources/SwiftTemplateUIDemo",
            exclude: ["AGENTS.md"]
        ),
        .executableTarget(
            name: "SwiftTemplateCLI",
            dependencies: [
                "SwiftTemplate",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/SwiftTemplateCLI",
            exclude: ["AGENTS.md"]
        ),
        .executableTarget(
            name: "SwiftTemplateExample",
            dependencies: ["SwiftTemplate"],
            path: "Sources/SwiftTemplateExample",
            exclude: ["AGENTS.md"]
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
        ),
        .testTarget(
            name: "SwiftTemplateUITests",
            dependencies: ["SwiftTemplateUI"],
            path: "Tests/SwiftTemplateUITests"
        )
    ]
)
