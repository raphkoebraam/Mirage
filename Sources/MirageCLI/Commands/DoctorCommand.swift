import ArgumentParser
import MirageKit

struct DoctorCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Check that the simulator environment is healthy."
    )

    func run() async throws {
        try await withErrorPresentation {
            let ui = CLIRuntime.ui
            let runner = CLIRuntime.runner

            // 1. Active developer directory.
            let xcodeSelect = try runner.run(
                Command(executable: "/usr/bin/xcode-select", arguments: ["-p"])
            )
            guard xcodeSelect.exitCode == 0 else {
                ui.error(
                    "No active developer directory. Install Xcode and run "
                        + "`xcode-select -s /Applications/Xcode.app`."
                )
                throw MirageCLIError("Environment is not healthy.")
            }
            let developerDir = xcodeSelect.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            ui.success("Xcode developer directory: \(developerDir)")

            // 2. simctl reachable and inventory parseable.
            let inventory: SimulatorInventory
            do {
                inventory = try CLIRuntime.simctl.list()
            } catch {
                ui.error("simctl is not responding: \(error)")
                throw MirageCLIError("Environment is not healthy.")
            }
            let runtimes = inventory.runtimes.filter(\.isAvailable)
            ui.success(
                "simctl is healthy: \(inventory.devices.count) device(s), "
                    + "\(runtimes.count) available runtime(s)."
            )

            // 3. Booted devices.
            let booted = inventory.bootedDevices
            if !booted.isEmpty {
                ui.info("Booted: \(booted.map(\.name).joined(separator: ", "))")
            }

            // 4. Hygiene signals.
            let unavailable = inventory.devices.count(where: { !$0.isAvailable })
            if unavailable > 0 {
                ui.warning(
                    "\(unavailable) unavailable device(s). Run `mirage cleanup` to remove them."
                )
            }

            let usage = DiskUsage(inventory: inventory)
            ui.info("Simulator data on disk: \(formatBytes(usage.totalBytes)). See `mirage disk-usage`.")
        }
    }
}
