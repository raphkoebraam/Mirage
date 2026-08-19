import ArgumentParser
import Foundation
import MirageKit

struct CleanupCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cleanup",
        abstract: "Slim down the simulator roster.",
        discussion: """
        Removes unavailable devices (their runtime is gone) and duplicates \
        (same name, type, and runtime; a booted copy is kept, else the most \
        recently used one, else the one with the most data). Booted devices \
        and watch-pair members are never touched. The plan is shown before \
        anything is deleted.
        """
    )

    @Flag(name: .long, help: "Also remove shutdown devices on non-latest runtimes.")
    var staleRuntimes = false

    @Option(
        name: .long,
        help: "Remove all shutdown devices on this runtime (version, name, or identifier). Repeatable."
    )
    var runtime: [String] = []

    @Option(
        name: [.customLong("images-not-used-since")],
        help: ArgumentHelp(
            "Also delete runtime disk images unused for this many days.",
            valueName: "days"
        )
    )
    var imagesNotUsedSince: Int?

    @Flag(name: .long, help: "Report what would be removed without deleting anything.")
    var dryRun = false

    @Flag(name: .shortAndLong, help: "Skip the confirmation prompt.")
    var yes = false

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui

            let inventory = try simctl.list()
            let requestedRuntimeIdentifiers = try resolveRequestedRuntimes(in: inventory)

            let plan = CleanupPlanner(inventory: inventory).plan(
                includeStaleRuntimes: staleRuntimes,
                runtimeIdentifiers: requestedRuntimeIdentifiers
            )

            warnAboutProtectedDevices(
                requested: requestedRuntimeIdentifiers,
                plan: plan,
                inventory: inventory,
                ui: ui
            )

            if plan.isEmpty, imagesNotUsedSince == nil {
                ui.info("Nothing to clean up.")
                return
            }

            if !plan.isEmpty {
                report(plan, in: inventory, ui: ui)
            }

            if dryRun {
                if let imagesNotUsedSince {
                    try ui.output(simctl.runtimeDeleteUnused(days: imagesNotUsedSince, dryRun: true))
                }
                return
            }

            try confirmDestructive(confirmationQuestion(for: plan), ui: ui, skip: yes)

            if !plan.isEmpty {
                try simctl.delete(udids: plan.deletedUDIDs)
                ui.success(
                    "Deleted \(plan.entries.count) simulator(s), reclaimed about "
                        + "\(formatBytes(plan.totalReclaimableBytes))."
                )
                if plan.entries.contains(where: { if case .duplicate = $0.reason { true } else { false } }) {
                    hintAboutXcodeDestinations(ui)
                }
            }

            if let imagesNotUsedSince {
                try pruneImages(unusedFor: imagesNotUsedSince, simctl: simctl, ui: ui)
            }
        }
    }

    private func confirmationQuestion(for plan: CleanupPlan) -> String {
        var actions: [String] = []
        if !plan.isEmpty {
            actions.append("delete \(plan.entries.count) simulator(s)")
        }
        if let imagesNotUsedSince {
            actions.append("delete runtime images unused for \(imagesNotUsedSince)+ days")
        }
        return "Proceed to \(actions.joined(separator: " and "))?"
    }

    /// When every device on an explicitly requested runtime survives the
    /// protections, say why instead of staying silent.
    private func warnAboutProtectedDevices(
        requested: Set<String>,
        plan: CleanupPlan,
        inventory: SimulatorInventory,
        ui: any UserInterface
    ) {
        guard !requested.isEmpty else { return }
        let planned = Set(plan.deletedUDIDs)
        let protected = inventory.availableDevices.filter { device in
            requested.contains(device.runtimeIdentifier) && !planned.contains(device.udid)
        }
        if !protected.isEmpty {
            ui.warning(
                "Skipped \(protected.count) protected device(s) on the requested runtime(s) "
                    + "(booted, mid-operation, or part of a watch pair)."
            )
        }
    }

    private func pruneImages(unusedFor days: Int, simctl: Simctl, ui: any UserInterface) throws {
        let report = try simctl.runtimeDeleteUnused(days: days, dryRun: false)
        if !report.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ui.output(report)
        }
        ui.success("Pruned runtime images unused for \(days)+ days.")
    }

    /// Expands each `--runtime` query into concrete runtime identifiers,
    /// failing loudly on queries that match nothing.
    private func resolveRequestedRuntimes(in inventory: SimulatorInventory) throws -> Set<String> {
        var identifiers = Set<String>()
        for query in runtime {
            let matches = inventory.runtimes(matching: query)
            guard !matches.isEmpty else {
                throw MirageCLIError(
                    "No available runtime matches '\(query)'. Run `mirage list runtimes` to see options."
                )
            }
            identifiers.formUnion(matches.map(\.identifier))
        }
        return identifiers
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
