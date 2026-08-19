import ArgumentParser
import Foundation
import MirageKit

struct BootCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "boot",
        abstract: "Boot a simulator."
    )

    @Argument(help: "Device name, UDID, UDID prefix, or 'booted'.")
    var device: String

    @Flag(name: .long, help: "Block until the device finishes booting.")
    var wait = false

    @Flag(name: .long, help: "Open the Simulator app afterwards.")
    var open = false

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui
            let resolved = try simctl.resolvedDevice(device)

            if resolved.isBooted {
                ui.info("\(resolved.name) is already booted.")
            } else {
                try await ui.progress("Booting \(resolved.name)", successMessage: nil) {
                    try simctl.boot(udid: resolved.udid)
                }
                if wait {
                    try await waitUntilBooted(resolved.udid, simctl: simctl)
                }
                ui.success("Booted \(resolved.name) (\(resolved.udid)).")
            }

            if open {
                try CLIRuntime.runner.runChecked(
                    Command(executable: "/usr/bin/open", arguments: ["-a", "Simulator"])
                )
            }
        }
    }

    private func waitUntilBooted(_ udid: String, simctl: Simctl, timeout: Duration = .seconds(60)) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            let device = try simctl.list().devices.first { $0.udid == udid }
            if device?.state == .booted {
                return
            }
            try await Task.sleep(for: .seconds(1))
        }
        throw MirageCLIError("Timed out waiting for the device to boot.")
    }
}

struct ShutdownCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "shutdown",
        abstract: "Shutdown simulators."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Flag(name: .long, help: "Shutdown every booted simulator.")
    var all = false

    func validate() throws {
        guard !(all && device != nil) else {
            throw ValidationError("Provide a device or --all, not both.")
        }
    }

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui

            if all {
                try simctl.shutdownAll()
                ui.success("Shut down all simulators.")
                return
            }

            let resolved = try simctl.resolvedTarget(device)
            try await ui.progress("Shutting down \(resolved.name)", successMessage: nil) {
                try simctl.shutdown(udid: resolved.udid)
            }
            ui.success("Shut down \(resolved.name).")
        }
    }
}

struct EraseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "erase",
        abstract: "Erase simulators' content and settings (factory reset)."
    )

    @Argument(help: "Devices to erase (name, UDID, prefix, or 'booted').")
    var devices: [String] = []

    @Flag(name: .long, help: "Erase every simulator.")
    var all = false

    @Flag(name: .shortAndLong, help: "Skip the confirmation prompt.")
    var yes = false

    func validate() throws {
        guard all != !devices.isEmpty else {
            throw ValidationError("Provide devices or --all (not both).")
        }
    }

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui

            if all {
                try confirmDestructive("Erase ALL simulators? This resets every device.", ui: ui, skip: yes)
                try simctl.eraseAll()
                ui.success("Erased all simulators.")
                return
            }

            let resolved = try devices.map(simctl.resolvedDevice)
            let names = resolved.map(\.name).joined(separator: ", ")
            try confirmDestructive("Erase \(names)? This resets content and settings.", ui: ui, skip: yes)
            try simctl.erase(udids: resolved.map(\.udid))
            ui.success("Erased \(names).")
        }
    }
}

struct CreateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new simulator.",
        discussion: "Device type and runtime accept fuzzy names ('iphone 17 pro', '26.0'). "
            + "Without --runtime the newest runtime for the device type is used; "
            + "without --name the device type's name is used."
    )

    @Option(name: .long, help: "Name for the new simulator. Defaults to the device type's name.")
    var name: String?

    @Option(name: .long, help: "Device type (name, substring, or identifier).")
    var type: String?

    @Option(name: .long, help: "Runtime (version, name, or identifier). Defaults to the newest compatible one.")
    var runtime: String?

    @Flag(name: .long, help: "Boot the device right after creating it.")
    var boot = false

    @Flag(name: .shortAndLong, help: "Assume yes for prompts, e.g. accepting the closest runtime match.")
    var yes = false

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui
            let inventory = try simctl.list()
            let resolver = DeviceResolver(inventory: inventory)

            let deviceType: DeviceType
            if let type {
                deviceType = try resolver.resolveDeviceType(type)
            } else if ui.isInteractive,
                      let chosen = ui.choose("Which device type?", options: inventory.deviceTypes.map(\.name)) {
                deviceType = try resolver.resolveDeviceType(chosen)
            } else {
                throw MirageCLIError("--type is required when running non-interactively.")
            }

            let resolvedRuntime = try resolveRuntimeForgivingly(
                runtime,
                for: deviceType,
                resolver: resolver,
                ui: ui,
                assumeYes: yes
            )
            try requireCompatible(deviceType, with: resolvedRuntime, in: inventory)

            let name = name ?? deviceType.name
            let udid = try simctl.create(
                name: name,
                deviceTypeIdentifier: deviceType.identifier,
                runtimeIdentifier: resolvedRuntime.identifier
            )

            ui.success("Created \(name) (\(deviceType.name), \(resolvedRuntime.name)).")
            ui.output(udid)
            hintAboutXcodeDestinations(ui)

            if boot {
                try await ui.progress("Booting \(name)", successMessage: nil) {
                    try simctl.boot(udid: udid)
                }
                ui.success("Booted \(name).")
            }
        }
    }
}

struct CloneCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clone",
        abstract: "Clone a simulator."
    )

    @Argument(help: "Source device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Option(name: .long, help: "Name for the clone.")
    var name: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui
            let resolved = try simctl.resolvedTarget(device)

            let udid = try simctl.clone(udid: resolved.udid, newName: name)

            ui.success("Cloned \(resolved.name) → \(name).")
            ui.output(udid)
        }
    }
}

struct DeleteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete simulators."
    )

    @Argument(help: "Devices to delete (name, UDID, prefix, or 'booted').")
    var devices: [String] = []

    @Flag(name: .long, help: "Delete simulators whose runtime is missing.")
    var unavailable = false

    @Flag(name: .long, help: "Delete every simulator.")
    var all = false

    @Flag(name: .shortAndLong, help: "Skip the confirmation prompt.")
    var yes = false

    func validate() throws {
        let modes = [!devices.isEmpty, unavailable, all].count(where: { $0 })
        guard modes == 1 else {
            throw ValidationError("Provide devices, --unavailable, or --all (exactly one).")
        }
    }

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui

            if unavailable {
                try confirmDestructive("Delete all unavailable simulators?", ui: ui, skip: yes)
                try simctl.deleteUnavailable()
                ui.success("Deleted unavailable simulators.")
                return
            }

            if all {
                try confirmDestructive("Delete ALL simulators? This cannot be undone.", ui: ui, skip: yes)
                try simctl.deleteAll()
                ui.success("Deleted all simulators.")
                return
            }

            let resolved = try devices.map(simctl.resolvedDevice)
            let names = resolved.map(\.name).joined(separator: ", ")
            try confirmDestructive("Delete \(names)? This cannot be undone.", ui: ui, skip: yes)
            try simctl.delete(udids: resolved.map(\.udid))
            ui.success("Deleted \(names).")
        }
    }
}

struct RenameCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rename",
        abstract: "Rename a simulator."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Option(name: .long, help: "The new name.")
    var name: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try simctl.rename(udid: resolved.udid, to: name)
            CLIRuntime.ui.success("Renamed \(resolved.name) → \(name).")
        }
    }
}

struct UpgradeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "upgrade",
        abstract: "Upgrade a simulator to a newer runtime."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Option(name: .long, help: "Target runtime (version, name, or identifier).")
    var runtime: String

    @Flag(name: .shortAndLong, help: "Assume yes for prompts, e.g. accepting the closest runtime match.")
    var yes = false

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let inventory = try simctl.list()
            let resolver = DeviceResolver(inventory: inventory)

            let resolved = try resolver.resolveTarget(device)
            let deviceType = resolved.deviceTypeIdentifier.flatMap(inventory.deviceType(withIdentifier:))
            let resolvedRuntime = try resolveRuntimeForgivingly(
                runtime,
                for: deviceType,
                resolver: resolver,
                ui: CLIRuntime.ui,
                assumeYes: yes
            )
            if let deviceType {
                try requireCompatible(deviceType, with: resolvedRuntime, in: inventory)
            }

            try simctl.upgrade(udid: resolved.udid, runtimeIdentifier: resolvedRuntime.identifier)
            CLIRuntime.ui.success("Upgraded \(resolved.name) to \(resolvedRuntime.name).")
        }
    }
}

/// Shared guard for destructive operations: prompts when possible, otherwise
/// requires an explicit --yes.
func confirmDestructive(_ question: String, ui: any UserInterface, skip: Bool) throws {
    guard !skip else { return }
    guard ui.isInteractive else {
        throw MirageCLIError("Refusing to run destructively without confirmation. Pass --yes to proceed.")
    }
    guard ui.confirm(question, defaultAnswer: false) else {
        throw MirageCLIError("Aborted.")
    }
}
