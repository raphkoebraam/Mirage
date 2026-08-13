import MirageKit
import MirageKitTesting
import Testing

@Suite("CleanupPlanner")
struct CleanupPlannerTests {
    let planner: CleanupPlanner

    init() throws {
        planner = try CleanupPlanner(inventory: SimulatorInventory(json: SimulatorFixtures.listJSON))
    }

    @Test("unavailable devices are always selected")
    func unavailable() {
        let plan = planner.plan()

        #expect(plan.entries.contains { entry in
            entry.device.name == "Old iPhone" && entry.reason == .unavailable
        })
    }

    @Test("duplicates keep the copy with the most data and delete the rest")
    func duplicatesKeepLargest() {
        let plan = planner.plan()

        // "CI Runner" exists twice on the same runtime; the 500 MB copy stays.
        #expect(plan.entries.contains { entry in
            entry.device.udid == "CBCBCBCB-5555-6666-7777-888888888888"
                && entry.reason == .duplicate(keptUDID: "CACACACA-1111-2222-3333-444444444444")
        })
        #expect(!plan.deletedUDIDs.contains("CACACACA-1111-2222-3333-444444444444"))
    }

    @Test("duplicates prefer keeping a booted device even with less data")
    func duplicatesKeepBooted() {
        let plan = planner.plan()

        // "iPhone 17 Pro" exists booted (18 MB) and shutdown (900 MB):
        // the booted one is kept regardless of size.
        #expect(plan.entries.contains { entry in
            entry.device.udid == "D0D0D0D0-AAAA-BBBB-CCCC-DDDDDDDDDDDD"
                && entry.reason == .duplicate(keptUDID: "9EC7498F-C644-4431-8CA5-CD1432170998")
        })
        #expect(!plan.deletedUDIDs.contains("9EC7498F-C644-4431-8CA5-CD1432170998"))
    }

    @Test("stale-runtime devices are only selected when opted in")
    func staleRuntimes() {
        let base = planner.plan()
        #expect(!base.deletedUDIDs.contains("DEDEDEDE-FAFA-1212-3434-565656565656"))

        let withStale = planner.plan(includeStaleRuntimes: true)
        #expect(withStale.entries.contains { entry in
            entry.device.udid == "DEDEDEDE-FAFA-1212-3434-565656565656"
                && entry.reason == .staleRuntime(newestRuntime: "iOS 26.0")
        })
    }

    @Test("devices mid-operation (creating/booting) are never selected")
    func skipsTransientStates() {
        let plan = planner.plan(includeStaleRuntimes: true)

        #expect(!plan.entries.contains { $0.device.name == "Fresh Device" })
    }

    @Test("booted devices are never selected")
    func neverDeletesBooted() {
        let plan = planner.plan(includeStaleRuntimes: true)

        #expect(!plan.entries.contains { $0.device.isBooted })
    }

    @Test("pair members are protected from duplicate and stale selection")
    func protectsPairMembers() throws {
        // The watch (pair member) sits on watchOS 26 alongside a fake older
        // watch runtime — it would be stale-eligible if not paired.
        let inventory = try SimulatorInventory(json: SimulatorFixtures.listJSON)
        let oldWatchRuntime = SimRuntime(
            identifier: "com.apple.CoreSimulator.SimRuntime.watchOS-11-0",
            name: "watchOS 11.0",
            version: "11.0",
            buildversion: "22R000",
            platform: "watchOS",
            isAvailable: true
        )
        let pairedWatchOnOldRuntime = Device(
            udid: "0B1E4D7C-A521-4AD7-B6BC-41B22D122118",
            name: "Apple Watch Series 11 (42mm)",
            state: .shutdown,
            isAvailable: true,
            deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-11-42mm",
            runtimeIdentifier: oldWatchRuntime.identifier,
            dataPathSize: 1000
        )
        let modified = SimulatorInventory(
            deviceTypes: inventory.deviceTypes,
            runtimes: inventory.runtimes + [oldWatchRuntime],
            devices: inventory.devices.filter { $0.udid != pairedWatchOnOldRuntime.udid }
                + [pairedWatchOnOldRuntime],
            pairs: inventory.pairs
        )

        let plan = CleanupPlanner(inventory: modified).plan(includeStaleRuntimes: true)

        #expect(!plan.deletedUDIDs.contains(pairedWatchOnOldRuntime.udid))
    }

    @Test("a clean inventory produces an empty plan")
    func cleanInventory() {
        let healthy = Device(
            udid: "AAAA0000-0000-0000-0000-000000000001",
            name: "Solo Phone",
            state: .shutdown,
            isAvailable: true,
            deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-26-0"
        )
        let inventory = SimulatorInventory(
            deviceTypes: [],
            runtimes: [
                SimRuntime(
                    identifier: "com.apple.CoreSimulator.SimRuntime.iOS-26-0",
                    name: "iOS 26.0",
                    version: "26.0",
                    buildversion: "23A339",
                    platform: "iOS",
                    isAvailable: true
                ),
            ],
            devices: [healthy],
            pairs: []
        )

        let plan = CleanupPlanner(inventory: inventory).plan(includeStaleRuntimes: true)

        #expect(plan.isEmpty)
    }

    @Test("entries are ordered by tier then name for stable reports")
    func deterministicOrdering() {
        let plan = planner.plan(includeStaleRuntimes: true)

        let names = plan.entries.map(\.device.name)
        #expect(names == ["Old iPhone", "CI Runner", "iPhone 17 Pro", "Test Phone"])
    }

    @Test("total reclaimable bytes sums the deleted devices' data")
    func totalBytes() {
        let plan = planner.plan()

        // Old iPhone (0) + CI Runner B (100 MB) + iPhone 17 Pro dup (900 MB).
        #expect(plan.totalReclaimableBytes == 104_857_600 + 943_718_400)
    }

    @Test("reasons render human-readable descriptions")
    func reasonDescriptions() {
        #expect(CleanupPlan.Reason.unavailable.description == "unavailable")
        #expect(CleanupPlan.Reason.duplicate(keptUDID: "ABCDEF12-0000").description.contains("ABCDEF12"))
        #expect(CleanupPlan.Reason.staleRuntime(newestRuntime: "iOS 26.0").description.contains("iOS 26.0"))
    }
}
