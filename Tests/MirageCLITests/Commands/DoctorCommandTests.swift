import ArgumentParser
import MirageKitTesting
import Testing
@testable import MirageCLI

@Suite("mirage doctor")
struct DoctorCommandTests {
    let harness = CLIHarness()

    @Test("reports healthy checks and flags unavailable devices")
    func healthy() async throws {
        harness.runner.stub(stdout: "/Applications/Xcode.app/Contents/Developer\n")
        harness.stubInventory()

        try await harness.run(["doctor"])

        #expect(harness.runner.executed.first?.executable == "/usr/bin/xcode-select")
        #expect(harness.ui.successMessages.contains { $0.contains("Xcode") })
        #expect(harness.ui.successMessages.contains { $0.contains("simctl") })
        // The fixture contains one unavailable device — doctor should point
        // at cleanup.
        #expect(harness.ui.events.contains { event in
            if case let .warning(message) = event { return message.contains("cleanup") }
            return false
        })
    }

    @Test("points at disk-usage, the command that exists, for the on-disk total")
    func diskUsageHint() async throws {
        harness.runner.stub(stdout: "/Applications/Xcode.app/Contents/Developer\n")
        harness.stubInventory()

        try await harness.run(["doctor"])

        let hint = harness.ui.events.compactMap { event -> String? in
            if case let .info(message) = event, message.contains("on disk") { return message }
            return nil
        }.first
        #expect(hint?.contains("mirage disk-usage") == true)
        #expect(hint?.contains("mirage du") == false)
    }

    @Test("fails with exit code 1 when Xcode is not selected")
    func noXcode() async throws {
        harness.runner.stub(stderr: "xcode-select: error: unable to get active developer directory\n", exitCode: 2)

        let exit = try await harness.runExpectingExit(["doctor"])

        #expect(exit == ExitCode(1))
        #expect(!harness.ui.errorMessages.isEmpty)
    }
}
