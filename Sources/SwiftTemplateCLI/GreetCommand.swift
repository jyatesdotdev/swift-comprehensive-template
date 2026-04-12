import ArgumentParser

/// Demonstrates @Argument, @Option, @Flag, and custom validation.
struct GreetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "greet",
        abstract: "Greet someone by name."
    )

    /// Positional argument — required by default.
    @Argument(help: "The name to greet.")
    var name: String

    /// Named option with a default value.
    @Option(name: .shortAndLong, help: "The greeting to use.")
    var greeting: String = "Hello"

    /// Repeat count with validation.
    @Option(name: .shortAndLong, help: "Number of times to repeat (1–100).")
    var count: Int = 1

    /// Boolean flag.
    @Flag(name: .shortAndLong, help: "SHOUT the greeting.")
    var shout = false

    /// Flag with inversion: --emoji / --no-emoji.
    @Flag(inversion: .prefixedNo, help: "Include emoji in output.")
    var emoji = true

    func validate() throws {
        guard (1...100).contains(count) else {
            throw ValidationError("--count must be between 1 and 100.")
        }
    }

    func run() throws {
        let prefix = emoji ? "👋 " : ""
        var message = "\(prefix)\(greeting), \(name)!"
        if shout { message = message.uppercased() }
        for _ in 0..<count {
            print(message)
        }
    }
}
