import ArgumentParser
import Foundation
import MirageKit

struct RuntimeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "runtime",
        abstract: "Manage runtime disk images.",
        subcommands: [
            RuntimeListCommand.self,
            RuntimeAvailableCommand.self,
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

struct RuntimeAvailableCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "available",
        abstract: "List simulator runtimes Apple offers for download.",
        discussion: """
        Reads the same catalog Xcode's Components pane uses and marks the \
        builds already installed. Install one with `mirage runtime install`.
        """
    )

    @Option(name: .long, help: "Only this platform: iOS, watchOS, tvOS, or visionOS.")
    var platform: String?

    @Flag(name: .long, help: "Include betas and release candidates.")
    var prerelease = false

    @Flag(name: .long, help: "Emit JSON instead of a table.")
    var json = false

    func validate() throws {
        if let platform, RuntimeInstallCommand.Platform(matching: platform) == nil {
            throw ValidationError(
                "Unknown platform '\(platform)'. Use iOS, watchOS, tvOS, or visionOS."
            )
        }
    }

    private struct Entry: Encodable {
        let platform: String
        let version: String
        let build: String
        let name: String
        let fileSize: Int64
        let isPrerelease: Bool
        let installed: Bool
    }

    func run() async throws {
        try await withErrorPresentation {
            let ui = CLIRuntime.ui

            let catalog: RuntimeCatalog
            do {
                catalog = try RuntimeCatalogFetcher(runner: CLIRuntime.runner).fetch()
            } catch let failure as CommandFailure {
                throw MirageCLIError("Could not download Apple's runtime catalog: \(failure.description)")
            }
            let installedBuilds = try Set(CLIRuntime.simctl.runtimeImages().map(\.build))

            var runtimes = platform.map { catalog.runtimes(platform: $0) } ?? catalog.runtimes
            if !prerelease {
                runtimes = runtimes.filter { !$0.isPrerelease }
            }

            let entries = runtimes.map { runtime in
                Entry(
                    platform: runtime.platform,
                    version: runtime.version,
                    build: runtime.build,
                    name: runtime.name,
                    fileSize: runtime.fileSize,
                    isPrerelease: runtime.isPrerelease,
                    installed: installedBuilds.contains(runtime.build)
                )
            }

            if json {
                try ui.output(prettyJSON(entries))
                return
            }

            ui.table(
                headers: ["Platform", "Version", "Build", "Size", "Status"],
                rows: entries.map { entry in
                    [
                        entry.platform,
                        entry.isPrerelease ? "\(entry.version) (\(prereleaseLabel(entry.name)))" : entry.version,
                        entry.build,
                        formatBytes(entry.fileSize),
                        entry.installed ? "installed" : "available",
                    ]
                }
            )
            ui.info("Install one with `mirage runtime install <platform> <version>`.")
        }
    }

    /// "iOS 26.5 beta 4 Simulator Runtime" -> "beta 4".
    private func prereleaseLabel(_ name: String) -> String {
        let stripped = name
            .replacingOccurrences(of: " Simulator Runtime", with: "")
            .split(separator: " ")
            .dropFirst(2)
            .joined(separator: " ")
        return stripped.isEmpty ? "prerelease" : stripped
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
