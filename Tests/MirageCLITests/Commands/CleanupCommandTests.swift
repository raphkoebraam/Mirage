import ArgumentParser
import MirageKitTesting
import Testing
@testable import MirageCLI

@Suite("mirage cleanup")
struct CleanupCommandTests {
    let harness = CLIHarness()

    @Test("deletes unavailable devices and duplicate losers after confirmation")
    func basicCleanup() async throws {
        harness.stubInventory()
        harness.ui.answerConfirm(true)

        try await harness.run(["cleanup"])

        #expect(harness.commandsAfterList.first?.arguments == [
            "simctl", "delete",
            "66666666-7777-8888-9999-000000000000",
            "CBCBCBCB-5555-6666-7777-888888888888",
            "D0D0D0D0-AAAA-BBBB-CCCC-DDDDDDDDDDDD",
        ])
        let table = try #require(harness.ui.tables.first)
        #expect(table.headers == ["Name", "Runtime", "Reason", "Size"])
        #expect(table.rows.count == 3)
        #expect(!harness.ui.successMessages.isEmpty)
    }

    @Test("--dry-run reports without deleting")
    func dryRun() async throws {
        harness.stubInventory()

        try await harness.run(["cleanup", "--dry-run"])

        #expect(harness.commandsAfterList.isEmpty)
        #expect(!harness.ui.tables.isEmpty)
    }

    @Test("declining the confirmation aborts with exit code 1")
    func declined() async throws {
        harness.stubInventory()
        harness.ui.answerConfirm(false)

        let exit = try await harness.runExpectingExit(["cleanup"])

        #expect(exit == ExitCode(1))
        #expect(harness.commandsAfterList.isEmpty)
    }

    @Test("--stale-runtimes widens the plan to old-runtime devices")
    func staleRuntimes() async throws {
        harness.stubInventory()

        try await harness.run(["cleanup", "--stale-runtimes", "--yes"])

        let deleted = try #require(harness.commandsAfterList.first?.arguments)
        #expect(deleted.contains("DEDEDEDE-FAFA-1212-3434-565656565656"))
    }

    @Test("--images-not-used-since prunes unused runtime images after device deletion")
    func runtimeImages() async throws {
        harness.stubInventory()

        try await harness.run(["cleanup", "--images-not-used-since", "30", "--yes"])

        #expect(harness.commandsAfterList.first?.arguments.first == "simctl")
        #expect(harness.commandsAfterList.first?.arguments[1] == "delete")
        #expect(harness.lastArguments == ["runtime", "delete", "--notUsedSinceDays", "30"])
    }

    @Test("--dry-run with --images-not-used-since uses simctl's own dry-run")
    func runtimeImagesDryRun() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "would delete image X\n")

        try await harness.run(["cleanup", "--images-not-used-since", "30", "--dry-run"])

        #expect(harness.commandsAfterList.count == 1)
        #expect(harness.lastArguments == ["runtime", "delete", "--notUsedSinceDays", "30", "--dry-run"])
        #expect(harness.ui.outputText.contains("would delete image X"))
    }

    @Test("--runtime deletes all shutdown devices on the requested version")
    func requestedRuntime() async throws {
        harness.stubInventory()

        try await harness.run(["cleanup", "--runtime", "18.4", "--yes"])

        let deleted = try #require(harness.commandsAfterList.first?.arguments)
        #expect(deleted.contains("DEDEDEDE-FAFA-1212-3434-565656565656"))
    }

    @Test("--runtime is repeatable")
    func repeatableRuntime() async throws {
        harness.stubInventory()

        try await harness.run(["cleanup", "--runtime", "18.4", "--runtime", "26.0", "--yes"])

        let deleted = try #require(harness.commandsAfterList.first?.arguments)
        #expect(deleted.contains("DEDEDEDE-FAFA-1212-3434-565656565656"))
        #expect(deleted.contains("CACACACA-1111-2222-3333-444444444444"))
        #expect(deleted.contains("11111111-2222-3333-4444-555555555555"))
        #expect(!deleted.contains("9EC7498F-C644-4431-8CA5-CD1432170998"))
    }

    @Test("--runtime explains when all matching devices are protected")
    func requestedRuntimeAllProtected() async throws {
        harness.stubInventory()

        // The only watchOS 26.0 device is a pair member; the base tiers still
        // find work, but the requested runtime itself yields nothing.
        try await harness.run(["cleanup", "--runtime", "watchOS 26.0", "--dry-run"])

        #expect(harness.ui.events.contains { event in
            if case let .warning(message) = event {
                return message.contains("protected")
            }
            return false
        })
    }

    @Test("an unknown --runtime fails with guidance and deletes nothing")
    func unknownRuntime() async throws {
        harness.stubInventory()

        let exit = try await harness.runExpectingExit(["cleanup", "--runtime", "99.9", "--yes"])

        #expect(exit == ExitCode(1))
        #expect(harness.ui.errorMessages.first?.contains("99.9") == true)
        #expect(harness.commandsAfterList.isEmpty)
    }

    @Test("a clean inventory reports nothing to do")
    func nothingToClean() async throws {
        harness.stubInventory(CleanFixture.json)

        try await harness.run(["cleanup"])

        #expect(harness.commandsAfterList.isEmpty)
        #expect(harness.ui.events.contains { event in
            if case let .info(message) = event { return message.contains("Nothing") }
            return false
        })
    }
}

/// A minimal healthy inventory: one device, one runtime, no pairs.
private enum CleanFixture {
    static let json = """
    {
      "devicetypes": [],
      "runtimes": [
        {
          "isAvailable": true,
          "version": "26.0",
          "isInternal": false,
          "buildversion": "23A339",
          "supportedArchitectures": ["arm64"],
          "supportedDeviceTypes": [],
          "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-0",
          "platform": "iOS",
          "bundlePath": "/tmp/r",
          "runtimeRoot": "/tmp/r/root",
          "name": "iOS 26.0"
        }
      ],
      "devices": {
        "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [
          {
            "dataPath": "/tmp/d",
            "dataPathSize": 13312,
            "logPath": "/tmp/l",
            "udid": "AAAA0000-0000-0000-0000-000000000001",
            "isAvailable": true,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "state": "Shutdown",
            "name": "Solo Phone"
          }
        ]
      },
      "pairs": {}
    }
    """
}
