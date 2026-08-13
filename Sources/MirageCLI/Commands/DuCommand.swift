import ArgumentParser
import MirageKit

struct DuCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "du",
        abstract: "Show simulator disk usage per runtime and per device.",
        discussion: "Read-only companion to `mirage cleanup`: see where the space goes before deleting."
    )

    @Option(name: .long, help: "How many devices to list in the biggest-devices table.")
    var top = 10

    @Flag(name: .long, help: "Emit JSON instead of tables.")
    var json = false

    func run() async throws {
        try await withErrorPresentation {
            let ui = CLIRuntime.ui
            let inventory = try CLIRuntime.simctl.list()
            let usage = DiskUsage(inventory: inventory)

            if json {
                let payload = JSONReport(
                    totalBytes: usage.totalBytes,
                    perRuntime: usage.perRuntime,
                    biggestDevices: usage.topDevices(top)
                )
                ui.output(try prettyJSON(payload))
                return
            }

            ui.table(
                headers: ["Runtime", "Devices", "Size"],
                rows: usage.perRuntime.map { runtime in
                    [runtime.runtimeName, String(runtime.deviceCount), formatBytes(runtime.totalBytes)]
                }
            )

            ui.table(
                headers: ["Device", "Runtime", "Size", "UDID"],
                rows: usage.topDevices(top).map { device in
                    [
                        device.name,
                        runtimeDisplayName(device.runtimeIdentifier, in: inventory),
                        formatBytes(device.dataPathSize ?? 0),
                        device.udid,
                    ]
                }
            )

            ui.info("Total simulator data: \(formatBytes(usage.totalBytes)) across \(inventory.devices.count) device(s).")
        }
    }

    private struct JSONReport: Codable {
        let totalBytes: Int64
        let perRuntime: [DiskUsage.RuntimeUsage]
        let biggestDevices: [Device]
    }
}
