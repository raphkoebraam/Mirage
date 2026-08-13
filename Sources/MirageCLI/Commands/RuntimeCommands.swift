import ArgumentParser
import MirageKit

struct RuntimeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "runtime",
        abstract: "Manage runtime disk images.",
        subcommands: [
            RuntimeListCommand.self,
            RuntimeInstallCommand.self,
            RuntimeDeleteCommand.self,
        ]
    )
}

struct RuntimeListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List runtime disk images."
    )

    func run() async throws {
        try await withErrorPresentation {
            try CLIRuntime.ui.output(CLIRuntime.simctl.runtimeList())
        }
    }
}

struct RuntimeInstallCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Download and install a simulator runtime.",
        discussion: "Wraps `xcodebuild -downloadPlatform`. Downloads are large (5–10 GB) and stream progress."
    )

    enum Platform: String, CaseIterable {
        case iOS, watchOS, tvOS, visionOS

        init?(matching raw: String) {
            self.init(rawValue: Platform.allCases.first {
                $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame
            }?.rawValue ?? raw)
        }
    }

    @Argument(help: "Platform: iOS, watchOS, tvOS, or visionOS.")
    var platform: String

    @Argument(help: "Runtime version (e.g. 26.2). Latest when omitted.")
    var version: String?

    func validate() throws {
        guard Platform(matching: platform) != nil else {
            throw ValidationError(
                "Unknown platform '\(platform)'. Use iOS, watchOS, tvOS, or visionOS."
            )
        }
    }

    func run() async throws {
        try await withErrorPresentation {
            let ui = CLIRuntime.ui
            let normalized = Platform(matching: platform)!.rawValue

            let code = try Xcodebuild(runner: CLIRuntime.runner)
                .downloadPlatform(normalized, buildVersion: version)
            guard code == 0 else {
                throw MirageCLIError("Runtime download failed (exit code \(code)).")
            }
            ui.success("Installed \(normalized) \(version ?? "latest") runtime.")
        }
    }
}

struct RuntimeDeleteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a runtime disk image ('all' deletes every image)."
    )

    @Argument(help: "Runtime image identifier (from `mirage runtime list`) or 'all'.")
    var identifier: String

    @Flag(name: .shortAndLong, help: "Skip the confirmation prompt.")
    var yes = false

    func run() async throws {
        try await withErrorPresentation {
            let ui = CLIRuntime.ui
            try confirmDestructive("Delete runtime image \(identifier)?", ui: ui, skip: yes)
            try CLIRuntime.simctl.runtimeDelete(identifier: identifier)
            ui.success("Deleted runtime image \(identifier).")
        }
    }
}
