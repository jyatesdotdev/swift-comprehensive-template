import ArgumentParser
import Foundation

// On Linux, URLSession lives in FoundationNetworking (not auto-imported).
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Demonstrates AsyncParsableCommand with @Argument and @Option.
struct FetchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fetch",
        abstract: "Fetch a URL and print response info (async command demo)."
    )

    @Argument(help: "The URL to fetch.")
    var url: String

    @Option(name: .shortAndLong, help: "Timeout in seconds.")
    var timeout: Double = 30.0

    @Flag(name: .shortAndLong, help: "Show response headers.")
    var verbose = false

    func validate() throws {
        guard Foundation.URL(string: url) != nil else {
            throw ValidationError("Invalid URL: \(url)")
        }
        guard timeout > 0 else {
            throw ValidationError("--timeout must be positive.")
        }
    }

    func run() async throws {
        guard let requestURL = Foundation.URL(string: url) else { return }

        var request = URLRequest(url: requestURL)
        request.timeoutInterval = timeout

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Non-HTTP response received.")
            return
        }

        print("Status: \(httpResponse.statusCode)")
        print("Size: \(data.count) bytes")

        if verbose {
            print("\nHeaders:")
            for (key, value) in httpResponse.allHeaderFields {
                print("  \(key): \(value)")
            }
        }
    }
}
