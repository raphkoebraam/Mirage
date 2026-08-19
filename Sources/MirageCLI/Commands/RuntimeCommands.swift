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
        discussion: "Wraps `xcodebuild -downloadPlatform`. Downloads are large (5 to 10 GB) and stream progress. "
            + "The version is checked against Apple's catalog first: `17` means 17.0, an already installed "
            + "build is reported instead of re-downloaded, and an unknown version lists what is available."
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

            var buildVersion = version
            if let version {
                switch try resolve(version, platform: normalized, ui: ui) {
                case let .download(resolvedVersion):
                    buildVersion = resolvedVersion
                case .alreadyInstalled:
                    return
                case .passThrough:
                    break
                }
            }

            let code = try Xcodebuild(runner: CLIRuntime.runner)
                .downloadPlatform(normalized, buildVersion: buildVersion)
            guard code == 0 else {
                throw MirageCLIError("Runtime download failed (exit code \(code)).")
            }
            ui.success("Installed \(normalized) \(buildVersion ?? "latest") runtime.")
        }
    }

    private enum Resolution {
        case download(version: String)
        case alreadyInstalled
        case passThrough
    }

    /// Checks the requested version against Apple's catalog so a miss is
    /// answered with what is available instead of xcodebuild's bare "not
    /// available for download". Offline, the request goes through unchanged.
    private func resolve(_ requested: String, platform: String, ui: any UserInterface) throws -> Resolution {
        let catalog: RuntimeCatalog
        do {
            catalog = try RuntimeCatalogFetcher(runner: CLIRuntime.runner).fetch()
        } catch let failure as CommandFailure {
            ui.warning("Could not check Apple's runtime catalog (\(failure.description)); asking xcodebuild directly.")
            return .passThrough
        }

        let offered = catalog.runtimes(platform: platform)
        // Exact (modulo trailing zeros): "17" is 17.0. Newest build first.
        if let match = offered.first(where: { DeviceResolver.versionsEqual($0.version, requested) }) {
            let installed = try CLIRuntime.simctl.runtimeImages().map(\.build)
            if installed.contains(match.build) {
                ui.info("\(platform) \(match.version) (\(match.build)) is already installed.")
                return .alreadyInstalled
            }
            return .download(version: match.version)
        }

        var lines = ["\(platform) \(requested) is not available for download."]
        let releases = uniqued(offered.filter { !$0.isPrerelease }.map(\.version))
        if !releases.isEmpty {
            lines.append("Available \(platform) releases: \(capped(releases)).")
        }
        // Betas of versions that already shipped add nothing; show only
        // pre-releases of versions with no release yet (e.g. the next major).
        let prereleases = uniqued(offered.filter(\.isPrerelease).map(\.version))
            .filter { !releases.contains($0) }
        if !prereleases.isEmpty {
            lines.append("Pre-releases: \(capped(prereleases)).")
        }
        lines.append("See `mirage runtime available --platform \(platform)`.")
        throw MirageCLIError(lines.joined(separator: "\n"))
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
