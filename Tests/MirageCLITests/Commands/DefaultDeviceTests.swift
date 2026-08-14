import ArgumentParser
import MirageKitTesting
import Testing
@testable import MirageCLI

@Suite("Omitted device defaults to booted")
struct DefaultDeviceTests {
    let harness = CLIHarness()

    @Test("screenshot with no device targets the booted simulator")
    func screenshot() async throws {
        harness.stubInventory()

        try await harness.run(["screenshot", "-o", "/tmp/shot.png"])

        #expect(harness.lastArguments == [
            "io", "9EC7498F-C644-4431-8CA5-CD1432170998", "screenshot", "/tmp/shot.png",
        ])
    }

    @Test("logs with no device targets the booted simulator")
    func logs() async throws {
        harness.stubInventory()
        harness.runner.stubInteractive(exitCode: 0)

        try await harness.run(["logs"])

        #expect(harness.lastArguments == [
            "spawn", "9EC7498F-C644-4431-8CA5-CD1432170998", "log", "stream",
        ])
    }

    @Test("shutdown with no device shuts down the booted simulator")
    func shutdown() async throws {
        harness.stubInventory()

        try await harness.run(["shutdown"])

        #expect(harness.lastArguments == ["shutdown", "9EC7498F-C644-4431-8CA5-CD1432170998"])
    }

    @Test("statusbar demo with no device targets the booted simulator")
    func statusbarDemo() async throws {
        harness.stubInventory()

        try await harness.run(["statusbar", "demo"])

        #expect(harness.lastArguments?.prefix(3) == [
            "status_bar", "9EC7498F-C644-4431-8CA5-CD1432170998", "override",
        ])
    }

    @Test("app list with no device targets the booted simulator")
    func appList() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "{}")

        try await harness.run(["app", "list", "--raw"])

        #expect(harness.lastArguments == ["listapps", "9EC7498F-C644-4431-8CA5-CD1432170998"])
    }

    @Test("the default fails helpfully when nothing is booted")
    func nothingBooted() async throws {
        harness.stubInventory(SimulatorFixtures.allShutdownJSON)

        let exit = try await harness.runExpectingExit(["screenshot"])

        #expect(exit == ExitCode(1))
        let message = try #require(harness.ui.errorMessages.first)
        #expect(message.contains("nothing is booted"))
    }
}

@Suite("ui commands with a single argument")
struct UIValueDisambiguationTests {
    let harness = CLIHarness()

    @Test("a known value targets the booted simulator")
    func valueOnly() async throws {
        harness.stubInventory()

        try await harness.run(["ui", "appearance", "dark"])

        #expect(harness.lastArguments == [
            "ui", "9EC7498F-C644-4431-8CA5-CD1432170998", "appearance", "dark",
        ])
    }

    @Test("anything else is treated as a device query (a get)")
    func deviceOnly() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "light\n")

        try await harness.run(["ui", "appearance", "ipad"])

        #expect(harness.lastArguments == [
            "ui", "11111111-2222-3333-4444-555555555555", "appearance",
        ])
        #expect(harness.ui.outputText == "light")
    }

    @Test("no arguments reads the booted simulator's setting")
    func neither() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "dark\n")

        try await harness.run(["ui", "appearance"])

        #expect(harness.lastArguments == [
            "ui", "9EC7498F-C644-4431-8CA5-CD1432170998", "appearance",
        ])
    }

    @Test("device and value together still work")
    func both() async throws {
        harness.stubInventory()

        try await harness.run(["ui", "increase-contrast", "ipad", "enabled"])

        #expect(harness.lastArguments == [
            "ui", "11111111-2222-3333-4444-555555555555", "increase_contrast", "enabled",
        ])
    }
}
