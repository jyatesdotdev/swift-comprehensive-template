import ArgumentParser
import SwiftTemplate

/// Root command for the SwiftTemplate CLI.
///
/// Demonstrates swift-argument-parser patterns including subcommands,
/// @Argument, @Option, @Flag, validation, and async commands.
@main
struct SwiftTemplateCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swift-template",
        abstract: "SwiftTemplate CLI — demonstrates argument-parser patterns and real-world CLI development.",
        version: SwiftTemplate.version,
        subcommands: [
            GreetCommand.self,
            GenerateCommand.self,
            FetchCommand.self,
            ConfigCommand.self,
            PipeCommand.self,
            FormatCommand.self,
            PlatformCommand.self
        ]
    )
}
