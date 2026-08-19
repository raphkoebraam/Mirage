import ArgumentParser
import MirageKit

struct GetenvCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "getenv",
        abstract: "Print an environment variable from a device."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Option(name: .long, help: "Variable name (e.g. HOME).")
    var variable: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try CLIRuntime.ui.output(simctl.getenv(udid: resolved.udid, variable: variable))
        }
    }
}

struct ICloudSyncCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "icloud-sync",
        abstract: "Trigger an iCloud sync on a device."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try simctl.icloudSync(udid: resolved.udid)
            CLIRuntime.ui.success("Triggered iCloud sync on \(resolved.name).")
        }
    }
}

struct LogverboseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logverbose",
        abstract: "Enable or disable verbose logging on a device."
    )

    enum Mode: String, EnumerableFlag {
        case on, off

        static func help(for value: Mode) -> ArgumentHelp? {
            switch value {
            case .on: "Enable verbose logging."
            case .off: "Disable verbose logging."
            }
        }
    }

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Flag(exclusivity: .exclusive)
    var mode: Mode

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try simctl.logverbose(udid: resolved.udid, enabled: mode == .on)
            let state = mode == .on ? "enabled" : "disabled"
            CLIRuntime.ui.success(
                "Verbose logging \(state) on \(resolved.name). Reboot the device for it to take effect."
            )
        }
    }
}

struct KeychainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "keychain",
        abstract: "Manipulate a device's keychain.",
        subcommands: [
            KeychainAddRootCertCommand.self,
            KeychainAddCertCommand.self,
            KeychainResetCommand.self,
        ]
    )
}

struct KeychainAddRootCertCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add-root-cert",
        abstract: "Add a certificate to the trusted root store."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Option(name: .long, help: "Path to the certificate.")
    var path: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try simctl.keychainAddRootCert(udid: resolved.udid, path: path)
            CLIRuntime.ui.success("Added root certificate to \(resolved.name).")
        }
    }
}

struct KeychainAddCertCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add-cert",
        abstract: "Add a certificate to the keychain."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Option(name: .long, help: "Path to the certificate.")
    var path: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try simctl.keychainAddCert(udid: resolved.udid, path: path)
            CLIRuntime.ui.success("Added certificate to \(resolved.name).")
        }
    }
}

struct KeychainResetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Reset the device's keychain."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Flag(name: .shortAndLong, help: "Skip the confirmation prompt.")
    var yes = false

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui
            let resolved = try simctl.resolvedTarget(device)
            try confirmDestructive("Reset the keychain on \(resolved.name)?", ui: ui, skip: yes)
            try simctl.keychainReset(udid: resolved.udid)
            ui.success("Keychain reset on \(resolved.name).")
        }
    }
}

struct LocationCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "location",
        abstract: "Control a device's simulated location.",
        subcommands: [
            LocationSetCommand.self,
            LocationClearCommand.self,
            LocationRunCommand.self,
            LocationListCommand.self,
        ]
    )
}

struct LocationSetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set a fixed location.",
        discussion: "Decimal degrees, e.g. --latitude 37.3349 --longitude -122.009."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    /// `.unconditional` lets negative coordinates through; otherwise "-122.009"
    /// would be read as a cluster of short options.
    @Option(name: .long, parsing: .unconditional, help: "Latitude in decimal degrees.")
    var latitude: Double

    @Option(name: .long, parsing: .unconditional, help: "Longitude in decimal degrees.")
    var longitude: Double

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try simctl.locationSet(udid: resolved.udid, latitude: latitude, longitude: longitude)
            CLIRuntime.ui.success("Location set to \(latitude),\(longitude) on \(resolved.name).")
        }
    }
}

struct LocationClearCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear",
        abstract: "Clear any simulated location."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try simctl.locationClear(udid: resolved.udid)
            CLIRuntime.ui.success("Cleared simulated location on \(resolved.name).")
        }
    }
}

struct LocationRunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run a location scenario (see `mirage location list`)."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Option(name: .long, help: "Scenario name.")
    var scenario: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try simctl.locationRun(udid: resolved.udid, scenario: scenario)
            CLIRuntime.ui.success("Running scenario '\(scenario)' on \(resolved.name).")
        }
    }
}

struct LocationListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available location scenarios."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try CLIRuntime.ui.output(simctl.locationList(udid: resolved.udid))
        }
    }
}

struct PasteboardCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pasteboard",
        abstract: "Work with a device's pasteboard.",
        subcommands: [
            PasteboardCopyCommand.self,
            PasteboardPasteCommand.self,
            PasteboardSyncCommand.self,
        ],
        aliases: ["pb"]
    )
}

struct PasteboardCopyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "copy",
        abstract: "Copy stdin onto the device pasteboard."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try simctl.pbcopy(udid: resolved.udid)
            CLIRuntime.ui.success("Copied stdin to \(resolved.name)'s pasteboard.")
        }
    }
}

struct PasteboardPasteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "paste",
        abstract: "Print the device pasteboard."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            try CLIRuntime.ui.output(simctl.pbpaste(udid: resolved.udid))
        }
    }
}

struct PasteboardSyncCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sync",
        abstract: "Sync the pasteboard between devices (or 'host')."
    )

    @Argument(help: "Source: device query or 'host'.")
    var source: String

    @Argument(help: "Destination: device query or 'host'.")
    var destination: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl

            func side(_ query: String) throws -> String {
                query == "host" ? "host" : try simctl.resolvedDevice(query).udid
            }

            try simctl.pbsync(source: side(source), destination: side(destination))
            CLIRuntime.ui.success("Pasteboard synced \(source) → \(destination).")
        }
    }
}

struct PairCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pair",
        abstract: "Pair a watch simulator with a phone simulator."
    )

    @Argument(help: "Watch device (name, UDID, prefix).")
    var watch: String

    @Argument(help: "Phone device (name, UDID, prefix).")
    var phone: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let inventory = try simctl.list()
            let resolver = DeviceResolver(inventory: inventory)

            let watchDevice = try resolver.resolveDevice(watch)
            let phoneDevice = try resolver.resolveDevice(phone)

            let pairUDID = try simctl.pair(watchUDID: watchDevice.udid, phoneUDID: phoneDevice.udid)
            CLIRuntime.ui.success("Paired \(watchDevice.name) with \(phoneDevice.name).")
            CLIRuntime.ui.output(pairUDID)
        }
    }
}

struct UnpairCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "unpair",
        abstract: "Unpair a watch–phone pair."
    )

    @Argument(help: "Pair UUID (see `mirage list pairs`).")
    var pair: String

    func run() async throws {
        try await withErrorPresentation {
            try CLIRuntime.simctl.unpair(pairUDID: pair)
            CLIRuntime.ui.success("Unpaired \(pair).")
        }
    }
}

struct PairActivateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pair-activate",
        abstract: "Set a pair as the active one."
    )

    @Argument(help: "Pair UUID (see `mirage list pairs`).")
    var pair: String

    func run() async throws {
        try await withErrorPresentation {
            try CLIRuntime.simctl.pairActivate(pairUDID: pair)
            CLIRuntime.ui.success("Activated pair \(pair).")
        }
    }
}

struct SpawnCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "spawn",
        abstract: "Spawn an executable on a device.",
        discussion: "Pass executable arguments after '--', e.g. `mirage spawn --executable /bin/ls -- -la`."
    )

    @Argument(help: "Device (name, UDID, or prefix); defaults to the booted simulator.")
    var device: String?

    @Option(name: .long, help: "Path to the executable on the device.")
    var executable: String

    @Argument(parsing: .postTerminator, help: "Arguments for the executable.")
    var executableArguments: [String] = []

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedTarget(device)
            let code = try simctl.spawn(
                udid: resolved.udid,
                executablePath: executable,
                arguments: executableArguments
            )
            if code != 0 {
                throw ExitCode(code)
            }
        }
    }
}

struct DiagnoseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "diagnose",
        abstract: "Collect simulator diagnostics and logs."
    )

    @Option(name: .long, help: "Output directory for the archive.")
    var output: String?

    @Flag(name: .long, help: "Include all logs, not just recent ones.")
    var allLogs = false

    @Option(name: .long, parsing: .upToNextOption, help: "Restrict to specific devices (queries).")
    var device: [String] = []

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let udids = try device.map { try simctl.resolvedDevice($0).udid }
            let code = try simctl.diagnose(outputPath: output, allLogs: allLogs, udids: udids)
            if code == 0 {
                CLIRuntime.ui.success("Diagnostics collected.")
            } else {
                throw MirageCLIError("diagnose failed (exit code \(code)).")
            }
        }
    }
}
