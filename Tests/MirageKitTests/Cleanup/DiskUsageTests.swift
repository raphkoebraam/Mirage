import MirageKit
import MirageKitTesting
import Testing

@Suite("DiskUsage")
struct DiskUsageTests {
    let usage: DiskUsage

    init() throws {
        usage = try DiskUsage(inventory: SimulatorInventory(json: SimulatorFixtures.listJSON))
    }

    @Test("aggregates bytes and device counts per runtime, largest first")
    func perRuntime() {
        let first = usage.perRuntime[0]
        #expect(first.runtimeName == "iOS 26.0")
        #expect(first.deviceCount == 7)
        #expect(first.totalBytes == 1_591_241_728)
    }

    @Test("computes the grand total")
    func total() {
        #expect(usage.totalBytes == 1_591_268_352)
    }

    @Test("lists the biggest devices first")
    func topDevices() {
        let top = usage.topDevices(2)
        #expect(top.map(\.udid) == [
            "D0D0D0D0-AAAA-BBBB-CCCC-DDDDDDDDDDDD", // 900 MB
            "CACACACA-1111-2222-3333-444444444444", // 500 MB
        ])
    }

    @Test("includes runtimes with zero-size devices")
    func zeroSizeRuntimes() {
        #expect(usage.perRuntime.contains { $0.runtimeName == "iOS 17.0" && $0.totalBytes == 0 })
    }
}
