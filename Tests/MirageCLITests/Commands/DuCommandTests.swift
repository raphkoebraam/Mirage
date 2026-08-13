import ArgumentParser
import Testing
@testable import MirageCLI

@Suite("mirage du")
struct DuCommandTests {
    let harness = CLIHarness()

    @Test("renders per-runtime usage and the biggest devices")
    func tables() async throws {
        harness.stubInventory()

        try await harness.run(["du"])

        #expect(harness.ui.tables.count == 2)
        let runtimeTable = harness.ui.tables[0]
        #expect(runtimeTable.headers == ["Runtime", "Devices", "Size"])
        #expect(runtimeTable.rows.first?.first == "iOS 26.0")

        let deviceTable = harness.ui.tables[1]
        #expect(deviceTable.rows.first?.first == "iPhone 17 Pro")

        #expect(harness.ui.events.contains { event in
            if case let .info(message) = event { return message.contains("Total") }
            return false
        })
    }

    @Test("--top limits the device table")
    func top() async throws {
        harness.stubInventory()

        try await harness.run(["du", "--top", "1"])

        #expect(harness.ui.tables[1].rows.count == 1)
    }

    @Test("--json emits the aggregates")
    func json() async throws {
        harness.stubInventory()

        try await harness.run(["du", "--json"])

        #expect(harness.ui.tables.isEmpty)
        #expect(harness.ui.outputText.contains("totalBytes"))
    }
}
