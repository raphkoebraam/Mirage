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
            RuntimeUninstallCommand.self,
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

    @Option(name: .long, help: "Platform: iOS, watchOS, tvOS, or visionOS.")
    var platform: String

    @Option(name: .long, help: "Runtime version (e.g. 26.2). Latest when omitted.")
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

struct RuntimeUninstallCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall a runtime disk image ('all' removes every image).",
        aliases: ["delete"]
    )

    @Argument(help: "Runtime version ('18' means 18.0), build, image identifier, or 'all'.")
    var identifier: String?

    /// Shadows the app-version flag on purpose: `runtime install --version`
    /// means the runtime version, so here it must too, not print the CLI
    /// version and quietly do nothing.
    @Option(name: .long, help: "Runtime version to uninstall (same as passing it as the argument).")
    var version: String?

    @Flag(name: .shortAndLong, help: "Skip the confirmation prompt.")
    var yes = false

    func validate() throws {
        guard (identifier != nil) != (version != nil) else {
            throw ValidationError("Provide a runtime (version, build, or identifier) or --version, not both.")
        }
    }

    func run() async throws {
        try await withErrorPresentation {
            let ui = CLIRuntime.ui
            let simctl = CLIRuntime.simctl
            let query = (identifier ?? version)!

            if query == "all" {
                try confirmDestructive("Delete ALL runtime images?", ui: ui, skip: yes)
                try simctl.runtimeDelete(identifier: "all")
                ui.success("Deleted all runtime images.")
                return
            }

            let image = try resolveImage(query, among: simctl.runtimeImages())
            let name = displayName(of: image)
            try confirmDestructive("Delete runtime image \(name)?", ui: ui, skip: yes)
            try simctl.runtimeDelete(identifier: image.identifier)
            ui.success("Deleted runtime image \(name).")
        }
    }

    /// simctl only accepts image identifiers or builds; a bare version like
    /// "18" would confirm and then fail. Resolve first so the prompt names
    /// the image and a miss lists what is installed.
    private func resolveImage(_ query: String, among images: [RuntimeImage]) throws -> RuntimeImage {
        let matches = images.filter { image in
            image.identifier.caseInsensitiveCompare(query) == .orderedSame
                || image.build.caseInsensitiveCompare(query) == .orderedSame
                || DeviceResolver.versionsEqual(image.version, query)
        }
        switch matches.count {
        case 1:
            return matches[0]
        case 0:
            var lines = ["No installed runtime image matches '\(query)'."]
            if !images.isEmpty {
                let sorted = images.sorted { lhs, rhs in
                    let lhsName = displayName(of: lhs)
                    let rhsName = displayName(of: rhs)
                    let lhsPlatform = lhsName.prefix { !$0.isWhitespace }
                    let rhsPlatform = rhsName.prefix { !$0.isWhitespace }
                    if lhsPlatform != rhsPlatform { return lhsPlatform < rhsPlatform }
                    return lhs.version.compare(rhs.version, options: .numeric) == .orderedDescending
                }
                lines.append("Installed images: \(sorted.map(displayName(of:)).joined(separator: ", ")).")
            }
            throw MirageCLIError(lines.joined(separator: "\n"))
        default:
            let candidates = matches.map(displayName(of:)).joined(separator: ", ")
            throw MirageCLIError("'\(query)' matches several images: \(candidates). Pass a build instead.")
        }
    }

    /// "iOS 26.5 (23F77)", derived from the simulator platform identifier.
    private func displayName(of image: RuntimeImage) -> String {
        let platform = switch image.platformIdentifier {
        case "com.apple.platform.iphonesimulator": "iOS"
        case "com.apple.platform.watchsimulator": "watchOS"
        case "com.apple.platform.appletvsimulator": "tvOS"
        case "com.apple.platform.xrsimulator": "visionOS"
        default: image.platformIdentifier ?? ""
        }
        let name = [platform, image.version].filter { !$0.isEmpty }.joined(separator: " ")
        return "\(name) (\(image.build))"
    }
}
