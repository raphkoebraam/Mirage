import ArgumentParser
import Testing
@testable import MirageCLI

@Suite("mirage getenv/icloud-sync/logverbose/keychain")
struct UtilityCommandTests {
    let harness = CLIHarness()

    @Test("getenv prints the variable value")
    func getenv() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "/data/home\n")

        try await harness.run(["getenv", "booted", "HOME"])

        #expect(harness.lastArguments == ["getenv", "9EC7498F-C644-4431-8CA5-CD1432170998", "HOME"])
        #expect(harness.ui.outputText == "/data/home")
    }

    @Test("icloud-sync triggers a sync")
    func icloudSync() async throws {
        harness.stubInventory()

        try await harness.run(["icloud-sync", "booted"])

        #expect(harness.lastArguments == ["icloud_sync", "9EC7498F-C644-4431-8CA5-CD1432170998"])
    }

    @Test("logverbose enables and disables")
    func logverbose() async throws {
        harness.stubInventory()

        try await harness.run(["logverbose", "booted", "on"])

        #expect(harness.lastArguments == ["logverbose", "9EC7498F-C644-4431-8CA5-CD1432170998", "enable"])
    }

    @Test("keychain add-root-cert passes the path")
    func keychainAddRootCert() async throws {
        harness.stubInventory()

        try await harness.run(["keychain", "add-root-cert", "booted", "/tmp/ca.pem"])

        #expect(harness.lastArguments == [
            "keychain", "9EC7498F-C644-4431-8CA5-CD1432170998", "add-root-cert", "/tmp/ca.pem",
        ])
    }

    @Test("keychain reset confirms before wiping")
    func keychainReset() async throws {
        harness.stubInventory()
        harness.ui.answerConfirm(true)

        try await harness.run(["keychain", "reset", "booted"])

        #expect(harness.lastArguments == ["keychain", "9EC7498F-C644-4431-8CA5-CD1432170998", "reset"])
    }
}

@Suite("mirage location")
struct LocationCommandTests {
    let harness = CLIHarness()

    @Test("location set parses lat,lon")
    func set() async throws {
        harness.stubInventory()

        try await harness.run(["location", "set", "booted", "37.3349,-122.009"])

        #expect(harness.lastArguments == [
            "location", "9EC7498F-C644-4431-8CA5-CD1432170998", "set", "37.3349,-122.009",
        ])
    }

    @Test("location set rejects malformed coordinates")
    func setInvalid() async throws {
        await #expect(throws: (any Error).self) {
            try await harness.run(["location", "set", "booted", "not-coords"])
        }
        #expect(harness.runner.executed.isEmpty)
    }

    @Test("location clear stops simulation")
    func clear() async throws {
        harness.stubInventory()

        try await harness.run(["location", "clear", "booted"])

        #expect(harness.lastArguments == ["location", "9EC7498F-C644-4431-8CA5-CD1432170998", "clear"])
    }

    @Test("location run starts a scenario")
    func runScenario() async throws {
        harness.stubInventory()

        try await harness.run(["location", "run", "booted", "City Bicycle Ride"])

        #expect(harness.lastArguments == [
            "location", "9EC7498F-C644-4431-8CA5-CD1432170998", "run", "City Bicycle Ride",
        ])
    }
}

@Suite("mirage pasteboard")
struct PasteboardCommandTests {
    let harness = CLIHarness()

    @Test("pasteboard copy pipes stdin to the device")
    func copy() async throws {
        harness.stubInventory()

        try await harness.run(["pasteboard", "copy", "booted"])

        #expect(harness.lastArguments == ["pbcopy", "9EC7498F-C644-4431-8CA5-CD1432170998"])
    }

    @Test("pasteboard paste prints device clipboard")
    func paste() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "clipboard!")

        try await harness.run(["pasteboard", "paste", "booted"])

        #expect(harness.lastArguments == ["pbpaste", "9EC7498F-C644-4431-8CA5-CD1432170998"])
        #expect(harness.ui.outputText == "clipboard!")
    }

    @Test("pasteboard sync resolves both sides, keeping 'host' literal")
    func sync() async throws {
        harness.stubInventory()

        try await harness.run(["pasteboard", "sync", "host", "booted"])

        #expect(harness.lastArguments == ["pbsync", "host", "9EC7498F-C644-4431-8CA5-CD1432170998"])
    }
}

@Suite("mirage pair/unpair")
struct PairCommandTests {
    let harness = CLIHarness()

    @Test("pair resolves watch and phone and prints the pair id")
    func pair() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "PAIR-UUID\n")

        try await harness.run(["pair", "watch", "iphone 17 pro"])

        #expect(harness.lastArguments == [
            "pair", "0B1E4D7C-A521-4AD7-B6BC-41B22D122118", "9EC7498F-C644-4431-8CA5-CD1432170998",
        ])
        #expect(harness.ui.outputText.contains("PAIR-UUID"))
    }

    @Test("unpair passes the pair UUID")
    func unpair() async throws {
        try await harness.run(["unpair", "E03C944C-146D-4895-AF08-E9D241390C5B"])

        #expect(harness.lastArguments == ["unpair", "E03C944C-146D-4895-AF08-E9D241390C5B"])
    }

    @Test("pair-activate passes the pair UUID")
    func pairActivate() async throws {
        try await harness.run(["pair-activate", "E03C944C-146D-4895-AF08-E9D241390C5B"])

        #expect(harness.lastArguments == ["pair_activate", "E03C944C-146D-4895-AF08-E9D241390C5B"])
    }
}

@Suite("mirage spawn/diagnose/runtime")
struct AdvancedCommandTests {
    let harness = CLIHarness()

    @Test("spawn runs the executable with arguments")
    func spawn() async throws {
        harness.stubInventory()
        harness.runner.stubInteractive(exitCode: 0)

        try await harness.run(["spawn", "booted", "/bin/ls", "--", "-la"])

        #expect(harness.lastArguments == [
            "spawn", "9EC7498F-C644-4431-8CA5-CD1432170998", "/bin/ls", "-la",
        ])
    }

    @Test("diagnose composes output options")
    func diagnose() async throws {
        harness.runner.stubInteractive(exitCode: 0)

        try await harness.run(["diagnose", "--output", "/tmp/diag", "--all-logs"])

        #expect(harness.lastArguments == ["diagnose", "-b", "--output=/tmp/diag", "--all-logs"])
    }

    @Test("runtime list prints raw output")
    func runtimeList() async throws {
        harness.runner.stub(stdout: "runtime-table")

        try await harness.run(["runtime", "list"])

        #expect(harness.lastArguments == ["runtime", "list"])
        #expect(harness.ui.outputText == "runtime-table")
    }

    @Test("runtime delete confirms before deleting")
    func runtimeDelete() async throws {
        harness.ui.answerConfirm(true)

        try await harness.run(["runtime", "delete", "ABC-123"])

        #expect(harness.lastArguments == ["runtime", "delete", "ABC-123"])
    }
}
