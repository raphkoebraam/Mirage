import ArgumentParser
import Foundation
import MirageKit

struct CleanupCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cleanup",
        abstract: "Slim down the simulator roster.",
        discussion: """
        Removes unavailable devices (their runtime is gone) and duplicates \
        (same name, type, and runtime — a booted copy is kept, else the one \
        with the most data). Booted devices and watch-pair members are never \
        touched. The plan is shown before anything is deleted.
        """
    )

    @Flag(name: .long, help: "Also remove shutdown devices on non-latest runtimes.")
    var staleRuntimes = false

    @Option(name: .long, help: "Also delete runtime disk images unused for this many days.")
    var runtimes: Int?

    @Flag(name: .long, help: "Report what would be removed without deleting anything.")
    var dryRun = false

    @Flag(name: .shortAndLong, help: "Skip the confirmation prompt.")
    var yes = false

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui

            let inventory = try simctl.list()
            let plan = CleanupPlanner(inventory: inventory).plan(includeStaleRuntimes: staleRuntimes)

            if plan.isEmpty, runtimes == nil {
                ui.info("Nothing to clean up.")
                return
            }

            if !plan.isEmpty {
                report(plan, in: inventory, ui: ui)
            }

            if dryRun {
                if let runtimes {
                    try ui.output(simctl.runtimeDeleteUnused(days: runtimes, dryRun: true))
                }
                return
            }

            var actions: [String] = []
            if !plan.isEmpty {
                actions.append("delete \(plan.entries.count) simulator(s)")
            }
            if let runtimes {
                actions.append("delete runtime images unused for \(runtimes)+ days")
            }
            try confirmDestructive(
                "Proceed to \(actions.joined(separator: " and "))?",
                ui: ui,
                skip: yes
            )

            if !plan.isEmpty {
                try simctl.delete(udids: plan.deletedUDIDs)
                ui.success(
                    "Deleted \(plan.entries.count) simulator(s), reclaimed about "
                        + "\(formatBytes(plan.totalReclaimableBytes))."
                )
            }

            if let runtimes {
                let report = try simctl.runtimeDeleteUnused(days: runtimes, dryRun: false)
                if !report.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ui.output(report)
                }
                ui.success("Pruned runtime images unused for \(runtimes)+ days.")
            }
        }
    }

    private func report(_ plan: CleanupPlan, in inventory: SimulatorInventory, ui: any UserInterface) {
        ui.table(
            headers: ["Name", "Runtime", "Reason", "Size"],
            rows: plan.entries.map { entry in
                [
                    entry.device.name,
                    runtimeDisplayName(entry.device.runtimeIdentifier, in: inventory),
                    entry.reason.description,
                    formatBytes(entry.device.dataPathSize ?? 0),
                ]
            }
        )
        ui.info(
            "Deleting \(plan.entries.count) simulator(s) reclaims about "
                + "\(formatBytes(plan.totalReclaimableBytes))."
        )
    }
}

func formatBytes(_ bytes: Int64) -> String {
    guard bytes > 0 else { return "—" }
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}
