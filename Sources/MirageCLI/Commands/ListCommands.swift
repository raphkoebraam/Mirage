import ArgumentParser
import Foundation
import MirageKit

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List simulators, runtimes, device types, or pairs.",
        subcommands: [
            ListDevicesCommand.self,
            ListRuntimesCommand.self,
            ListDeviceTypesCommand.self,
            ListPairsCommand.self,
        ],
        defaultSubcommand: ListDevicesCommand.self
    )
}

struct ListDevicesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "devices",
        abstract: "List simulator devices (the default)."
    )

    @Flag(name: .long, help: "Emit JSON instead of a table.")
    var json = false

    @Flag(name: .long, help: "Include unavailable devices.")
    var all = false

    @Option(name: .long, help: "Only devices whose name contains this text.")
    var name: String?

    func run() async throws {
        try await withErrorPresentation {
            let inventory = try CLIRuntime.simctl.list()

            var devices = all ? inventory.devices : inventory.availableDevices
            if let name {
                devices = devices.filter { $0.name.localizedCaseInsensitiveContains(name) }
            }

            if json {
                CLIRuntime.ui.output(try prettyJSON(devices))
                return
            }

            CLIRuntime.ui.table(
                headers: ["Name", "State", "Runtime", "UDID"],
                rows: devices.map { device in
                    [
                        device.name,
                        device.state.rawValue,
                        runtimeDisplayName(device.runtimeIdentifier, in: inventory),
                        device.udid,
                    ]
                }
            )
        }
    }
}

struct ListRuntimesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "runtimes",
        abstract: "List installed simulator runtimes."
    )

    @Flag(name: .long, help: "Emit JSON instead of a table.")
    var json = false

    func run() async throws {
        try await withErrorPresentation {
            let inventory = try CLIRuntime.simctl.list()

            if json {
                CLIRuntime.ui.output(try prettyJSON(inventory.runtimes))
                return
            }

            CLIRuntime.ui.table(
                headers: ["Name", "Version", "Build", "Available", "Identifier"],
                rows: inventory.runtimes.map { runtime in
                    [
                        runtime.name,
                        runtime.version,
                        runtime.buildversion,
                        runtime.isAvailable ? "yes" : "no",
                        runtime.identifier,
                    ]
                }
            )
        }
    }
}

struct ListDeviceTypesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "devicetypes",
        abstract: "List available device types."
    )

    @Flag(name: .long, help: "Emit JSON instead of a table.")
    var json = false

    @Option(name: .long, help: "Only device types in this product family (iPhone, iPad, Apple Watch, Apple TV, Apple Vision).")
    var family: String?

    func run() async throws {
        try await withErrorPresentation {
            let inventory = try CLIRuntime.simctl.list()

            var types = inventory.deviceTypes
            if let family {
                types = types.filter { $0.productFamily.caseInsensitiveCompare(family) == .orderedSame }
            }

            if json {
                CLIRuntime.ui.output(try prettyJSON(types))
                return
            }

            CLIRuntime.ui.table(
                headers: ["Name", "Family", "Identifier"],
                rows: types.map { [$0.name, $0.productFamily, $0.identifier] }
            )
        }
    }
}

struct ListPairsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pairs",
        abstract: "List watch–phone pairs."
    )

    func run() async throws {
        try await withErrorPresentation {
            let inventory = try CLIRuntime.simctl.list()

            CLIRuntime.ui.table(
                headers: ["Watch", "Phone", "State", "Pair UDID"],
                rows: inventory.pairs.map { pair in
                    [pair.watch.name, pair.phone.name, pair.state, pair.udid]
                }
            )
        }
    }
}

struct BootedCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "booted",
        abstract: "List currently booted simulators."
    )

    @Flag(name: .long, help: "Emit JSON instead of a table.")
    var json = false

    func run() async throws {
        try await withErrorPresentation {
            let inventory = try CLIRuntime.simctl.list()
            let booted = inventory.bootedDevices

            if json {
                CLIRuntime.ui.output(try prettyJSON(booted))
                return
            }

            if booted.isEmpty {
                CLIRuntime.ui.info("No simulators are booted.")
                return
            }

            CLIRuntime.ui.table(
                headers: ["Name", "Runtime", "UDID"],
                rows: booted.map { device in
                    [device.name, runtimeDisplayName(device.runtimeIdentifier, in: inventory), device.udid]
                }
            )
        }
    }
}

func runtimeDisplayName(_ identifier: String, in inventory: SimulatorInventory) -> String {
    inventory.runtime(withIdentifier: identifier)?.name
        ?? identifier.replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
}

func prettyJSON(_ value: some Encodable) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return String(decoding: try encoder.encode(value), as: UTF8.self)
}
