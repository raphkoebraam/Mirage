import ArgumentParser
import Testing
@testable import MirageCLI

@Suite("mirage screenshot/record/media")
struct IOCommandTests {
    let harness = CLIHarness()

    @Test("screenshot with explicit output and options")
    func screenshot() async throws {
        harness.stubInventory()

        try await harness.run([
            "screenshot", "booted", "--output", "/tmp/shot.png", "--type", "jpeg", "--mask", "black",
        ])

        #expect(harness.lastArguments == [
            "io", "9EC7498F-C644-4431-8CA5-CD1432170998", "screenshot",
            "--type=jpeg", "--mask=black", "/tmp/shot.png",
        ])
        #expect(harness.ui.outputText == "/tmp/shot.png")
    }

    @Test("screenshot defaults to a timestamped png in the working directory")
    func screenshotDefaultPath() async throws {
        harness.stubInventory()

        try await harness.run(["screenshot", "booted"])

        let path = try #require(harness.lastArguments?.last)
        #expect(path.hasSuffix(".png"))
        #expect(path.contains("iPhone-17-Pro"))
    }

    @Test("record passes codec and force flags and defaults to .mov")
    func record() async throws {
        harness.stubInventory()
        harness.runner.stubInteractive(exitCode: 0)

        try await harness.run(["record", "booted", "--output", "/tmp/video.mov", "--codec", "h264", "--force"])

        #expect(harness.lastArguments == [
            "io", "9EC7498F-C644-4431-8CA5-CD1432170998", "recordVideo",
            "--codec=h264", "--force", "/tmp/video.mov",
        ])
    }

    @Test("media add forwards all file paths")
    func mediaAdd() async throws {
        harness.stubInventory()

        try await harness.run(["media", "add", "booted", "/tmp/a.png", "/tmp/b.mov"])

        #expect(harness.lastArguments == [
            "addmedia", "9EC7498F-C644-4431-8CA5-CD1432170998", "/tmp/a.png", "/tmp/b.mov",
        ])
    }
}

@Suite("mirage open/push/privacy")
struct SystemCommandTests {
    let harness = CLIHarness()

    @Test("open forwards the URL")
    func openURL() async throws {
        harness.stubInventory()

        try await harness.run(["open", "booted", "https://example.com/path"])

        #expect(harness.lastArguments == [
            "openurl", "9EC7498F-C644-4431-8CA5-CD1432170998", "https://example.com/path",
        ])
    }

    @Test("push sends a payload file to a bundle id")
    func push() async throws {
        harness.stubInventory()

        try await harness.run(["push", "booted", "com.example.app", "/tmp/payload.json"])

        #expect(harness.lastArguments == [
            "push", "9EC7498F-C644-4431-8CA5-CD1432170998", "com.example.app", "/tmp/payload.json",
        ])
    }

    @Test("push without payload reads stdin")
    func pushStdin() async throws {
        harness.stubInventory()

        try await harness.run(["push", "booted", "com.example.app"])

        #expect(harness.lastArguments == [
            "push", "9EC7498F-C644-4431-8CA5-CD1432170998", "com.example.app", "-",
        ])
    }

    @Test("privacy grant requires a bundle id")
    func privacyGrantWithoutBundle() async throws {
        await #expect(throws: (any Error).self) {
            try await harness.run(["privacy", "grant", "booted", "photos"])
        }
        #expect(harness.runner.executed.isEmpty)
    }

    @Test("privacy grant maps action, service, and bundle id")
    func privacyGrant() async throws {
        harness.stubInventory()

        try await harness.run(["privacy", "grant", "booted", "photos", "com.example.app"])

        #expect(harness.lastArguments == [
            "privacy", "9EC7498F-C644-4431-8CA5-CD1432170998", "grant", "photos", "com.example.app",
        ])
    }

    @Test("privacy reset works without a bundle id")
    func privacyReset() async throws {
        harness.stubInventory()

        try await harness.run(["privacy", "reset", "booted", "all"])

        #expect(harness.lastArguments == [
            "privacy", "9EC7498F-C644-4431-8CA5-CD1432170998", "reset", "all",
        ])
    }
}

@Suite("mirage statusbar/ui")
struct StatusBarUICommandTests {
    let harness = CLIHarness()

    @Test("statusbar override composes only the provided flags")
    func statusbarOverride() async throws {
        harness.stubInventory()

        try await harness.run([
            "statusbar", "override", "booted",
            "--time", "9:41", "--battery-level", "100", "--battery-state", "charged",
        ])

        #expect(harness.lastArguments == [
            "status_bar", "9EC7498F-C644-4431-8CA5-CD1432170998", "override",
            "--time", "9:41", "--batteryState", "charged", "--batteryLevel", "100",
        ])
    }

    @Test("statusbar override with no flags is rejected")
    func statusbarOverrideEmpty() async throws {
        await #expect(throws: (any Error).self) {
            try await harness.run(["statusbar", "override", "booted"])
        }
        #expect(harness.runner.executed.isEmpty)
    }

    @Test("statusbar demo applies the App Store screenshot preset")
    func statusbarDemo() async throws {
        harness.stubInventory()

        try await harness.run(["statusbar", "demo", "booted"])

        #expect(harness.lastArguments == [
            "status_bar", "9EC7498F-C644-4431-8CA5-CD1432170998", "override",
            "--time", "9:41",
            "--dataNetwork", "wifi",
            "--wifiMode", "active",
            "--wifiBars", "3",
            "--cellularMode", "active",
            "--cellularBars", "4",
            "--batteryState", "charged",
            "--batteryLevel", "100",
        ])
    }

    @Test("statusbar clear")
    func statusbarClear() async throws {
        harness.stubInventory()

        try await harness.run(["statusbar", "clear", "booted"])

        #expect(harness.lastArguments == ["status_bar", "9EC7498F-C644-4431-8CA5-CD1432170998", "clear"])
    }

    @Test("ui appearance set and get")
    func uiAppearance() async throws {
        harness.stubInventory()

        try await harness.run(["ui", "appearance", "booted", "dark"])
        #expect(harness.lastArguments == ["ui", "9EC7498F-C644-4431-8CA5-CD1432170998", "appearance", "dark"])

        let second = CLIHarness()
        second.stubInventory()
        second.runner.stub(stdout: "dark\n")
        try await second.run(["ui", "appearance", "booted"])
        #expect(second.lastArguments == ["ui", "9EC7498F-C644-4431-8CA5-CD1432170998", "appearance"])
        #expect(second.ui.outputText == "dark")
    }

    @Test("ui content-size maps to content_size")
    func uiContentSize() async throws {
        harness.stubInventory()

        try await harness.run(["ui", "content-size", "booted", "extra-large"])

        #expect(harness.lastArguments == [
            "ui", "9EC7498F-C644-4431-8CA5-CD1432170998", "content_size", "extra-large",
        ])
    }

    @Test("ui increase-contrast maps to increase_contrast")
    func uiIncreaseContrast() async throws {
        harness.stubInventory()

        try await harness.run(["ui", "increase-contrast", "booted", "enabled"])

        #expect(harness.lastArguments == [
            "ui", "9EC7498F-C644-4431-8CA5-CD1432170998", "increase_contrast", "enabled",
        ])
    }
}
