import ArgumentParser
import Testing
@testable import MirageCLI

@Suite("mirage app")
struct AppCommandTests {
    let harness = CLIHarness()

    @Test("app install resolves the device and passes the path")
    func install() async throws {
        harness.stubInventory()

        try await harness.run(["app", "install", "booted", "/tmp/My.app"])

        #expect(harness.lastArguments == ["install", "9EC7498F-C644-4431-8CA5-CD1432170998", "/tmp/My.app"])
    }

    @Test("app uninstall passes the bundle id")
    func uninstall() async throws {
        harness.stubInventory()

        try await harness.run(["app", "uninstall", "booted", "com.example.app"])

        #expect(harness.lastArguments == ["uninstall", "9EC7498F-C644-4431-8CA5-CD1432170998", "com.example.app"])
    }

    @Test("app launch forwards launch arguments after --")
    func launch() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "com.example.app: 777\n")

        try await harness.run(["app", "launch", "booted", "com.example.app", "--", "-AppleLocale", "en_US"])

        #expect(harness.lastArguments == [
            "launch", "9EC7498F-C644-4431-8CA5-CD1432170998", "com.example.app", "-AppleLocale", "en_US",
        ])
        #expect(harness.ui.successMessages.first?.contains("777") == true)
    }

    @Test("app launch --console streams interactively")
    func launchConsole() async throws {
        harness.stubInventory()

        try await harness.run(["app", "launch", "booted", "com.example.app", "--console"])

        #expect(harness.lastArguments == [
            "launch", "--console-pty", "9EC7498F-C644-4431-8CA5-CD1432170998", "com.example.app",
        ])
    }

    @Test("app terminate passes the bundle id")
    func terminate() async throws {
        harness.stubInventory()

        try await harness.run(["app", "terminate", "booted", "com.example.app"])

        #expect(harness.lastArguments == ["terminate", "9EC7498F-C644-4431-8CA5-CD1432170998", "com.example.app"])
    }

    @Test("app list prints raw listapps output")
    func list() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "apps-plist-output")

        try await harness.run(["app", "list", "booted"])

        #expect(harness.lastArguments == ["listapps", "9EC7498F-C644-4431-8CA5-CD1432170998"])
        #expect(harness.ui.outputText.contains("apps-plist-output"))
    }

    @Test("app info prints raw appinfo output")
    func info() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "info-output")

        try await harness.run(["app", "info", "booted", "com.example.app"])

        #expect(harness.lastArguments == ["appinfo", "9EC7498F-C644-4431-8CA5-CD1432170998", "com.example.app"])
        #expect(harness.ui.outputText.contains("info-output"))
    }

    @Test("app container prints the path and accepts a container kind")
    func container() async throws {
        harness.stubInventory()
        harness.runner.stub(stdout: "/containers/data\n")

        try await harness.run(["app", "container", "booted", "com.example.app", "data"])

        #expect(harness.lastArguments == [
            "get_app_container", "9EC7498F-C644-4431-8CA5-CD1432170998", "com.example.app", "data",
        ])
        #expect(harness.ui.outputText == "/containers/data")
    }

    @Test("app install-data passes the xcappdata path")
    func installData() async throws {
        harness.stubInventory()

        try await harness.run(["app", "install-data", "booted", "/tmp/data.xcappdata"])

        #expect(harness.lastArguments == [
            "install_app_data", "9EC7498F-C644-4431-8CA5-CD1432170998", "/tmp/data.xcappdata",
        ])
    }
}
