import ArgumentParser
import MirageKit
import Testing
@testable import MirageCLI

@Suite("mirage boot/shutdown/erase")
struct BootShutdownEraseTests {
    let harness = CLIHarness()

    @Test("boot resolves a name to a UDID and reports success")
    func boot() async throws {
        harness.stubInventory()

        try await harness.run(["boot", "Fresh Device"])

        #expect(harness.lastArguments == ["boot", "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"])
        #expect(!harness.ui.successMessages.isEmpty)
    }

    @Test("MIRAGE_DEVICE_SET routes every simctl call through --set")
    func deviceSet() async throws {
        harness.stubInventory()

        try await CLIRuntime.$deviceSet.withValue("/tmp/farm") {
            try await harness.run(["boot", "Fresh Device"])
        }

        #expect(harness.lastArguments == [
            "--set", "/tmp/farm", "boot", "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
        ])
    }

    @Test("boot surfaces resolution failures as themed errors with exit code 1")
    func bootUnknownDevice() async throws {
        harness.stubInventory()

        let exit = try await harness.runExpectingExit(["boot", "nonexistent"])

        #expect(exit == ExitCode(1))
        #expect(harness.ui.errorMessages.first?.contains("nonexistent") == true)
        #expect(harness.commandsAfterList.isEmpty)
    }

    @Test("shutdown accepts 'booted'")
    func shutdownBooted() async throws {
        harness.stubInventory()

        try await harness.run(["shutdown", "booted"])

        #expect(harness.lastArguments == ["shutdown", "9EC7498F-C644-4431-8CA5-CD1432170998"])
    }

    @Test("shutdown --all skips resolution entirely")
    func shutdownAll() async throws {
        try await harness.run(["shutdown", "--all"])

        #expect(harness.runner.executed.count == 1)
        #expect(harness.lastArguments == ["shutdown", "all"])
    }

    @Test("erase requires confirmation and aborts when declined")
    func eraseDeclined() async throws {
        harness.stubInventory()
        harness.ui.answerConfirm(false)

        let exit = try await harness.runExpectingExit(["erase", "Fresh Device"])

        #expect(exit == ExitCode(1))
        #expect(harness.commandsAfterList.isEmpty)
    }

    @Test("erase --yes skips confirmation")
    func eraseForced() async throws {
        harness.stubInventory()

        try await harness.run(["erase", "Fresh Device", "--yes"])

        #expect(harness.lastArguments == ["erase", "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"])
        #expect(!harness.ui.events.contains { if case .confirm = $0 { true } else { false } })
    }

    @Test("erase --all --yes maps to simctl erase all")
    func eraseAll() async throws {
        try await harness.run(["erase", "--all", "--yes"])

        #expect(harness.lastArguments == ["erase", "all"])
    }
}

@Suite("mirage create/clone/delete/rename")
struct CreateCloneDeleteRenameTests {
    let harness = CLIHarness()

    @Test("create resolves fuzzy type and defaults to its newest runtime")
    func create() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "NEW-UDID\n")

        try await harness.run(["create", "--name", "My Phone", "--type", "iphone 17 pro"])

        #expect(harness.lastArguments == [
            "create", "My Phone",
            "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "com.apple.CoreSimulator.SimRuntime.iOS-26-0",
        ])
        #expect(harness.ui.outputText.contains("NEW-UDID"))
    }

    @Test("create tells interactive users how to surface the device in Xcode")
    func createXcodeHint() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "NEW-UDID\n")

        try await harness.run(["create", "--name", "My Phone", "--type", "iphone 17 pro"])

        #expect(harness.ui.events.contains { event in
            if case let .info(message) = event { return message.contains("Manage Run Destinations") }
            return false
        })

        let quiet = CLIHarness(isInteractive: false)
        quiet.stubInventory()
        quiet.runner.stub(stdout: "NEW-UDID\n")
        try await quiet.run(["create", "--name", "My Phone", "--type", "iphone 17 pro"])
        #expect(!quiet.ui.events.contains { if case .info = $0 { true } else { false } })
    }

    @Test("create without --name uses the device type's name")
    func createDefaultName() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "NEW-UDID\n")

        try await harness.run(["create", "--type", "iphone 17 pro"])

        #expect(harness.lastArguments == [
            "create", "iPhone 17 Pro",
            "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "com.apple.CoreSimulator.SimRuntime.iOS-26-0",
        ])
    }

    @Test("create rejects a positional name")
    func createRejectsPositionalName() {
        #expect(throws: (any Error).self) {
            try Mirage.parseAsRoot(["create", "My Phone", "--type", "iphone 17 pro"])
        }
    }

    @Test("create accepts an explicit runtime version")
    func createWithRuntime() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "NEW-UDID\n")

        try await harness.run(["create", "--name", "Old Phone", "--type", "iphone 17 pro", "--runtime", "18.4"])

        #expect(harness.lastArguments == [
            "create", "Old Phone",
            "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "com.apple.CoreSimulator.SimRuntime.iOS-18-4",
        ])
    }

    @Test("create without --type fails non-interactively with guidance")
    func createWithoutType() async throws {
        let harness = CLIHarness(isInteractive: false)
        harness.stubInventory()

        let exit = try await harness.runExpectingExit(["create", "--name", "My Phone"])

        #expect(exit == ExitCode(1))
        #expect(harness.ui.errorMessages.first?.contains("--type") == true)
    }

    @Test("create without --type prompts interactively")
    func createPromptsForType() async throws {
        harness.stubInventory()
        harness.ui.answerChoose("iPhone 17 Pro")
        harness.runner.stub(stdout: "NEW-UDID\n")

        try await harness.run(["create", "--name", "My Phone"])

        #expect(harness.lastArguments?.first == "create")
        #expect(harness.lastArguments?[2] == "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro")
    }

    @Test("a major-only runtime version resolves to its .0 release without prompting")
    func createMajorOnlyRuntime() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "NEW-UDID\n")

        try await harness.run(["create", "--name", "Test", "--type", "iphone 17 pro", "--runtime", "18"])

        #expect(!harness.ui.events.contains { if case .confirm = $0 { true } else { false } })
        #expect(harness.lastArguments == [
            "create", "Test",
            "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "com.apple.CoreSimulator.SimRuntime.iOS-18-0",
        ])
    }

    @Test("a near-miss runtime asks 'did you mean' and proceeds on yes")
    func createRuntimeSuggestionAccepted() async throws {
        harness.stubInventory()
        harness.ui.answerConfirm(true)
        harness.runner.stub(stdout: "NEW-UDID\n")

        try await harness.run(["create", "--name", "Test", "--type", "iphone 17 pro", "--runtime", "18.3"])

        #expect(harness.ui.events.contains { event in
            if case let .confirm(question) = event { return question.contains("iOS 18.4") }
            return false
        })
        #expect(harness.lastArguments == [
            "create", "Test",
            "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "com.apple.CoreSimulator.SimRuntime.iOS-18-4",
        ])
    }

    @Test("declining the runtime suggestion aborts without creating")
    func createRuntimeSuggestionDeclined() async throws {
        harness.stubInventory()
        harness.ui.answerConfirm(false)

        let exit = try await harness.runExpectingExit([
            "create", "--name", "Test", "--type", "iphone 17 pro", "--runtime", "18.3",
        ])

        #expect(exit == ExitCode(1))
        #expect(harness.commandsAfterList.isEmpty)
    }

    @Test("non-interactive near-miss fails but names the closest runtime")
    func createRuntimeSuggestionNonInteractive() async throws {
        let harness = CLIHarness(isInteractive: false)
        harness.stubInventory()

        let exit = try await harness.runExpectingExit([
            "create", "--name", "Test", "--type", "iphone 17 pro", "--runtime", "18.3",
        ])

        #expect(exit == ExitCode(1))
        #expect(harness.ui.errorMessages.first?.contains("iOS 18.4") == true)
    }

    @Test("an incompatible family redirects to the closest runtime that works")
    func createRuntimeRedirect() async throws {
        harness.stubInventory()
        harness.ui.answerConfirm(true)
        harness.runner.stub(stdout: "NEW-UDID\n")

        // 18.x exists but cannot run the iPad in this fixture.
        try await harness.run(["create", "--name", "Test", "--type", "ipad", "--runtime", "18.3"])

        #expect(harness.ui.events.contains { event in
            if case let .confirm(question) = event {
                return question.contains("can run iPad Pro 13-inch (M4)") && question.contains("iOS 26.0")
            }
            return false
        })
        #expect(harness.lastArguments?.last == "com.apple.CoreSimulator.SimRuntime.iOS-26-0")
    }

    @Test("--yes auto-accepts the closest runtime without prompting")
    func createRuntimeSuggestionAutoAccepted() async throws {
        let harness = CLIHarness(isInteractive: false)
        harness.stubInventory()
        harness.runner.stub(stdout: "NEW-UDID\n")

        try await harness.run(["create", "--name", "Test", "--type", "iphone 17 pro", "--runtime", "18.3", "--yes"])

        #expect(!harness.ui.events.contains { if case .confirm = $0 { true } else { false } })
        #expect(harness.ui.events.contains { event in
            if case let .info(message) = event { return message.contains("iOS 18.4") }
            return false
        })
        #expect(harness.lastArguments == [
            "create", "Test",
            "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "com.apple.CoreSimulator.SimRuntime.iOS-18-4",
        ])
    }

    @Test("an incompatible type/runtime pair fails with compatibility guidance")
    func createIncompatible() async throws {
        harness.stubInventory()

        let exit = try await harness.runExpectingExit([
            "create", "--name", "Test", "--type", "ipad", "--runtime", "18.4",
        ])

        #expect(exit == ExitCode(1))
        let message = try #require(harness.ui.errorMessages.first)
        #expect(message.contains("iPad Pro 13-inch (M4)"))
        #expect(message.contains("iOS 26.0")) // runtimes that DO support it
        #expect(message.contains("iPhone 17 Pro")) // devices iOS 18.4 DOES support
        #expect(harness.commandsAfterList.isEmpty)
    }

    @Test("create --boot boots the freshly created device")
    func createAndBoot() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "NEW-UDID\n")

        try await harness.run(["create", "--name", "My Phone", "--type", "iphone 17 pro", "--boot"])

        #expect(harness.commandsAfterList.map { Array($0.arguments.dropFirst()) } == [
            [
                "create",
                "My Phone",
                "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
                "com.apple.CoreSimulator.SimRuntime.iOS-26-0",
            ],
            ["boot", "NEW-UDID"],
        ])
    }

    @Test("clone maps resolved source and new name")
    func clone() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "CLONE-UDID\n")

        try await harness.run(["clone", "Fresh Device", "--name", "Fresh Copy"])

        #expect(harness.lastArguments == ["clone", "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE", "Fresh Copy"])
    }

    @Test("clone without a device targets the booted simulator")
    func cloneBooted() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "CLONE-UDID\n")

        try await harness.run(["clone", "--name", "Booted Copy"])

        #expect(harness.lastArguments == ["clone", "9EC7498F-C644-4431-8CA5-CD1432170998", "Booted Copy"])
    }

    @Test("delete resolves multiple devices and confirms once")
    func delete() async throws {
        harness.stubInventory()
        harness.ui.answerConfirm(true)

        try await harness.run(["delete", "Fresh Device", "ipad"])

        #expect(harness.lastArguments == [
            "delete",
            "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
            "11111111-2222-3333-4444-555555555555",
        ])
    }

    @Test("delete --unavailable needs no device arguments")
    func deleteUnavailable() async throws {
        try await harness.run(["delete", "--unavailable", "--yes"])

        #expect(harness.lastArguments == ["delete", "unavailable"])
    }

    @Test("delete --all requires confirmation and honors decline")
    func deleteAllDeclined() async throws {
        harness.ui.answerConfirm(false)

        let exit = try await harness.runExpectingExit(["delete", "--all"])

        #expect(exit == ExitCode(1))
        #expect(harness.runner.executed.isEmpty)
    }

    @Test("rename resolves the device and passes the new name")
    func rename() async throws {
        harness.stubInventory()

        try await harness.run(["rename", "Fresh Device", "--name", "Better Name"])

        #expect(harness.lastArguments == ["rename", "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE", "Better Name"])
    }

    @Test("upgrade resolves device and runtime")
    func upgrade() async throws {
        harness.stubInventory()

        try await harness.run(["upgrade", "Fresh Device", "--runtime", "26.0"])

        #expect(harness.lastArguments == [
            "upgrade", "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
            "com.apple.CoreSimulator.SimRuntime.iOS-26-0",
        ])
    }
}

@Suite("mirage list/booted")
struct ListCommandTests {
    let harness = CLIHarness()

    @Test("list renders a device table by default")
    func listDevices() async throws {
        harness.stubInventory()

        try await harness.run(["list"])

        let table = try #require(harness.ui.tables.first)
        #expect(table.headers == ["Name", "State", "Runtime", "UDID"])
        #expect(table.rows.contains { $0[0] == "iPhone 17 Pro" && $0[1] == "Booted" })
        // Unavailable devices are excluded from the default listing.
        #expect(!table.rows.contains { $0[0] == "Old iPhone" })
    }

    @Test("list --json emits machine-readable devices")
    func listJSON() async throws {
        harness.stubInventory()

        try await harness.run(["list", "--json"])

        #expect(harness.ui.tables.isEmpty)
        #expect(harness.ui.outputText.contains("\"udid\""))
    }

    @Test("list runtimes renders the runtime table")
    func listRuntimes() async throws {
        harness.stubInventory()

        try await harness.run(["list", "runtimes"])

        let table = try #require(harness.ui.tables.first)
        #expect(table.headers.contains("Version"))
        #expect(table.rows.contains { $0.contains("iOS 26.0") })
    }

    @Test("list devicetypes renders the device type table")
    func listDeviceTypes() async throws {
        harness.stubInventory()

        try await harness.run(["list", "devicetypes"])

        let table = try #require(harness.ui.tables.first)
        #expect(table.rows.contains { $0.contains("iPhone 17 Pro") })
    }

    @Test("list pairs renders watch-phone pairs")
    func listPairs() async throws {
        harness.stubInventory()

        try await harness.run(["list", "pairs"])

        let table = try #require(harness.ui.tables.first)
        #expect(table.rows.first?.contains("iPhone 17 Pro") == true)
    }

    @Test("booted lists only booted devices")
    func booted() async throws {
        harness.stubInventory()

        try await harness.run(["booted"])

        let table = try #require(harness.ui.tables.first)
        #expect(table.rows.count == 1)
        #expect(table.rows[0][0] == "iPhone 17 Pro")
    }
}
