import ArgumentParser
import MirageKit

struct AppCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app",
        abstract: "Install, launch, and inspect apps on a simulator.",
        subcommands: [
            AppInstallCommand.self,
            AppUninstallCommand.self,
            AppLaunchCommand.self,
            AppTerminateCommand.self,
            AppListCommand.self,
            AppInfoCommand.self,
            AppContainerCommand.self,
            AppInstallDataCommand.self,
        ]
    )
}

struct AppInstallCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install an app bundle."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "Path to the .app bundle.")
    var path: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try simctl.install(udid: resolved.udid, appPath: path)
            CLIRuntime.ui.success("Installed \(path) on \(resolved.name).")
        }
    }
}

struct AppUninstallCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall an app."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "The app's bundle identifier.")
    var bundleID: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try simctl.uninstall(udid: resolved.udid, bundleID: bundleID)
            CLIRuntime.ui.success("Uninstalled \(bundleID) from \(resolved.name).")
        }
    }
}

struct AppLaunchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "launch",
        abstract: "Launch an app.",
        discussion: "Pass app arguments after '--', e.g. `mirage app launch booted com.example -- -AppleLocale en_US`."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "The app's bundle identifier.")
    var bundleID: String

    @Flag(name: .long, help: "Stream the app's console output (Ctrl-C to stop).")
    var console = false

    @Flag(name: .long, help: "Wait for a debugger to attach before running.")
    var waitForDebugger = false

    @Flag(name: .long, help: "Terminate an already-running instance first.")
    var terminateRunning = false

    @Argument(parsing: .postTerminator, help: "Arguments passed to the app.")
    var appArguments: [String] = []

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui
            let resolved = try simctl.resolvedDevice(device)

            if console {
                _ = try simctl.launchWithConsole(
                    udid: resolved.udid,
                    bundleID: bundleID,
                    arguments: appArguments,
                    waitForDebugger: waitForDebugger,
                    terminateRunningProcess: terminateRunning
                )
                return
            }

            let pid = try simctl.launch(
                udid: resolved.udid,
                bundleID: bundleID,
                arguments: appArguments,
                waitForDebugger: waitForDebugger,
                terminateRunningProcess: terminateRunning
            )

            if let pid {
                ui.success("Launched \(bundleID) on \(resolved.name) (pid \(pid)).")
            } else {
                ui.success("Launched \(bundleID) on \(resolved.name).")
            }
        }
    }
}

struct AppTerminateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "terminate",
        abstract: "Terminate a running app."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "The app's bundle identifier.")
    var bundleID: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try simctl.terminate(udid: resolved.udid, bundleID: bundleID)
            CLIRuntime.ui.success("Terminated \(bundleID) on \(resolved.name).")
        }
    }
}

struct AppListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List installed apps."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Flag(name: .long, help: "Emit JSON instead of a table.")
    var json = false

    @Flag(name: .long, help: "Pass simctl's raw plist output through unchanged.")
    var raw = false

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui
            let resolved = try simctl.resolvedDevice(device)
            let output = try simctl.listApps(udid: resolved.udid)

            if raw {
                ui.output(output)
                return
            }

            guard let apps = try? InstalledApp.parse(listappsOutput: output) else {
                // New Xcode releases may change the format; degrade gracefully.
                ui.output(output)
                return
            }

            if json {
                try ui.output(prettyJSON(apps))
                return
            }

            ui.table(
                headers: ["Name", "Bundle ID", "Type", "Version"],
                rows: apps.map { app in
                    [
                        app.displayName ?? "—",
                        app.bundleID,
                        app.applicationType ?? "—",
                        app.version ?? "—",
                    ]
                }
            )
        }
    }
}

struct AppInfoCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Show information about an installed app."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "The app's bundle identifier.")
    var bundleID: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try CLIRuntime.ui.output(simctl.appInfo(udid: resolved.udid, bundleID: bundleID))
        }
    }
}

struct AppContainerCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "container",
        abstract: "Print an app container path.",
        discussion: "Container kinds: app, data, groups, or an app group identifier."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "The app's bundle identifier.")
    var bundleID: String

    @Argument(help: "Container kind (app, data, groups, or a group id).")
    var container: String?

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try CLIRuntime.ui.output(
                simctl.appContainer(udid: resolved.udid, bundleID: bundleID, container: container)
            )
        }
    }
}

struct AppInstallDataCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install-data",
        abstract: "Install an .xcappdata package, replacing the app's data container."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "Path to the .xcappdata package.")
    var path: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try simctl.installAppData(udid: resolved.udid, path: path)
            CLIRuntime.ui.success("Installed app data on \(resolved.name).")
        }
    }
}
