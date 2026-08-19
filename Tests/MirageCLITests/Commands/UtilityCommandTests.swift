import ArgumentParser
import MirageKitTesting
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

    /// Stubs the catalog download and the installed-image listing that
    /// `runtime install <platform> <version>` consults before xcodebuild.
    private func stubCatalog() {
        harness.runner.stub(stdout: RuntimeFixtures.downloadableIndexPlist)
        harness.runner.stub(stdout: RuntimeFixtures.runtimeListJSON)
    }

    @Test("runtime install resolves the version against Apple's catalog, then downloads")
    func runtimeInstall() async throws {
        stubCatalog()
        harness.runner.stubInteractive(exitCode: 0)

        // "27" means 27.0; the catalog's 27.0 entry is a release candidate.
        try await harness.run(["runtime", "install", "iOS", "27"])

        #expect(harness.runner.lastCommand?.arguments == [
            "xcodebuild", "-downloadPlatform", "iOS", "-buildVersion", "27.0",
        ])
        #expect(!harness.ui.successMessages.isEmpty)
    }

    @Test("runtime install lists what is available when the version is not in the catalog")
    func runtimeInstallUnknownVersion() async throws {
        stubCatalog()

        let exit = try await harness.runExpectingExit(["runtime", "install", "iOS", "17"])

        #expect(exit == ExitCode(1))
        let message = try #require(harness.ui.errorMessages.first)
        #expect(message.contains("iOS 17"))
        #expect(message.contains("27.0"))
        #expect(message.contains("26.5"))
        #expect(message.contains("mirage runtime available"))
        #expect(!harness.runner.executed.contains { $0.arguments.first == "xcodebuild" })
    }

    @Test("runtime install skips the download when the build is already installed")
    func runtimeInstallAlreadyInstalled() async throws {
        stubCatalog()

        try await harness.run(["runtime", "install", "iOS", "26.5"])

        #expect(!harness.runner.executed.contains { $0.arguments.first == "xcodebuild" })
        #expect(harness.ui.events.contains { event in
            if case let .info(message) = event { return message.contains("already installed") }
            return false
        })
    }

    @Test("runtime install falls back to xcodebuild when the catalog cannot be fetched")
    func runtimeInstallOffline() async throws {
        harness.runner.stub(stderr: "curl: (6) Could not resolve host", exitCode: 6)
        harness.runner.stubInteractive(exitCode: 0)

        try await harness.run(["runtime", "install", "iOS", "26.2"])

        #expect(harness.runner.lastCommand?.arguments == [
            "xcodebuild", "-downloadPlatform", "iOS", "-buildVersion", "26.2",
        ])
        #expect(harness.ui.events.contains { if case .warning = $0 { true } else { false } })
    }

    @Test("runtime install normalizes platform casing and defaults to latest without consulting the catalog")
    func runtimeInstallLatest() async throws {
        harness.runner.stubInteractive(exitCode: 0)

        try await harness.run(["runtime", "install", "ios"])

        #expect(harness.runner.executed.count == 1)
        #expect(harness.runner.lastCommand?.arguments == ["xcodebuild", "-downloadPlatform", "iOS"])
    }

    @Test("runtime install rejects unknown platforms")
    func runtimeInstallUnknownPlatform() async throws {
        await #expect(throws: (any Error).self) {
            try await harness.run(["runtime", "install", "android"])
        }
        #expect(harness.runner.executed.isEmpty)
    }

    @Test("runtime uninstall resolves a version to the installed image and confirms")
    func runtimeUninstall() async throws {
        harness.runner.stub(stdout: RuntimeFixtures.runtimeListJSON)
        harness.ui.answerConfirm(true)

        try await harness.run(["runtime", "uninstall", "26.5"])

        #expect(harness.lastArguments == ["runtime", "delete", "F5C0D8C6-39E5-42F6-A211-22892CFF099C"])
        #expect(harness.ui.events.contains { event in
            if case let .confirm(question) = event { return question.contains("iOS 26.5 (23F77)") }
            return false
        })
    }

    @Test("runtime delete stays as an alias of uninstall")
    func runtimeUninstallByBuildViaAlias() async throws {
        harness.runner.stub(stdout: RuntimeFixtures.runtimeListJSON)

        try await harness.run(["runtime", "delete", "23T239", "--yes"])

        #expect(harness.lastArguments == ["runtime", "delete", "7FA94CC6-EA5D-4069-ADF8-17BC943A0CC2"])
    }

    @Test("runtime uninstall lists installed images when nothing matches")
    func runtimeUninstallUnknown() async throws {
        harness.runner.stub(stdout: RuntimeFixtures.runtimeListJSON)

        let exit = try await harness.runExpectingExit(["runtime", "uninstall", "18"])

        #expect(exit == ExitCode(1))
        let message = try #require(harness.ui.errorMessages.first)
        #expect(message.contains("'18'"))
        #expect(message.contains("iOS 26.5 (23F77)"))
        #expect(message.contains("watchOS 26.4 (23T239)"))
        // Nothing was deleted and nobody was prompted for a doomed action.
        #expect(harness.runner.executed.count == 1)
        #expect(!harness.ui.events.contains { if case .confirm = $0 { true } else { false } })
    }

    @Test("runtime uninstall all skips resolution and removes every image")
    func runtimeUninstallAll() async throws {
        harness.ui.answerConfirm(true)

        try await harness.run(["runtime", "uninstall", "all"])

        #expect(harness.runner.executed.count == 1)
        #expect(harness.lastArguments == ["runtime", "delete", "all"])
    }
}
