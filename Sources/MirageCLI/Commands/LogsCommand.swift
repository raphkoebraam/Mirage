import ArgumentParser
import MirageKit

struct LogsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logs",
        abstract: "Stream a device's unified log (Ctrl-C to stop).",
        discussion: "Wraps `log stream` on the device. Use --app for a quick "
            + "process filter or --predicate for full NSPredicate syntax."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Option(name: .long, help: "NSPredicate filter, e.g. 'subsystem == \"com.example\"'.")
    var predicate: String?

    @Option(name: .long, help: "Shortcut: only logs from this process name.")
    var app: String?

    @Option(name: .long, help: "Log level: default, info, or debug.")
    var level: String?

    func validate() throws {
        guard predicate == nil || app == nil else {
            throw ValidationError("Provide either --predicate or --app, not both.")
        }
    }

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)

            var arguments = ["log", "stream"]
            if let filter = predicate ?? app.map({ "process == \"\($0)\"" }) {
                arguments += ["--predicate", filter]
            }
            if let level {
                arguments += ["--level", level]
            }

            _ = try simctl.spawn(
                udid: resolved.udid,
                executablePath: arguments[0],
                arguments: Array(arguments.dropFirst())
            )
        }
    }
}
