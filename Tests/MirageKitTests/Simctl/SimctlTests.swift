import Foundation
import MirageKit
import MirageKitTesting
import Testing

/// Every test asserts the exact `xcrun simctl` argv the client produces:
/// the contract between mirage and Apple's tooling.
@Suite("Simctl invocations")
struct SimctlTests {
    let runner = MockCommandRunner()
    var simctl: Simctl {
        Simctl(runner: runner)
    }

    private func expectLast(_ arguments: [String]) {
        #expect(runner.lastCommand == Command(executable: "/usr/bin/xcrun", arguments: ["simctl"] + arguments))
    }

    // MARK: - Inventory

    @Test("list requests JSON and parses the inventory")
    func list() throws {
        runner.stub(stdout: SimulatorFixtures.listJSON)

        let inventory = try simctl.list()

        expectLast(["list", "-j"])
        #expect(inventory.devices.count == 10)
    }

    // MARK: - Device lifecycle

    @Test("create passes name, device type, and runtime; returns the new UDID")
    func create() throws {
        runner.stub(stdout: "0FE28DBF-6COD-4A50-9F97-97B41787E7E2\n")

        let udid = try simctl.create(
            name: "CI iPhone",
            deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-26-0"
        )

        expectLast([
            "create", "CI iPhone",
            "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "com.apple.CoreSimulator.SimRuntime.iOS-26-0",
        ])
        #expect(udid == "0FE28DBF-6COD-4A50-9F97-97B41787E7E2")
    }

    @Test("create omits the runtime when not provided")
    func createWithoutRuntime() throws {
        _ = try simctl.create(
            name: "X",
            deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            runtimeIdentifier: nil
        )

        expectLast(["create", "X", "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"])
    }

    @Test func boot() throws {
        try simctl.boot(udid: "UDID-1")
        expectLast(["boot", "UDID-1"])
    }

    @Test func shutdown() throws {
        try simctl.shutdown(udid: "UDID-1")
        expectLast(["shutdown", "UDID-1"])
    }

    @Test func shutdownAll() throws {
        try simctl.shutdownAll()
        expectLast(["shutdown", "all"])
    }

    @Test func erase() throws {
        try simctl.erase(udids: ["A", "B"])
        expectLast(["erase", "A", "B"])
    }

    @Test func eraseAll() throws {
        try simctl.eraseAll()
        expectLast(["erase", "all"])
    }

    @Test func delete() throws {
        try simctl.delete(udids: ["A", "B"])
        expectLast(["delete", "A", "B"])
    }

    @Test func deleteUnavailable() throws {
        try simctl.deleteUnavailable()
        expectLast(["delete", "unavailable"])
    }

    @Test func deleteAll() throws {
        try simctl.deleteAll()
        expectLast(["delete", "all"])
    }

    @Test("clone returns the new device's UDID")
    func clone() throws {
        runner.stub(stdout: "NEW-UDID\n")

        let udid = try simctl.clone(udid: "SRC", newName: "Copy")

        expectLast(["clone", "SRC", "Copy"])
        #expect(udid == "NEW-UDID")
    }

    @Test func rename() throws {
        try simctl.rename(udid: "UDID-1", to: "New Name")
        expectLast(["rename", "UDID-1", "New Name"])
    }

    @Test func upgrade() throws {
        try simctl.upgrade(udid: "UDID-1", runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-26-0")
        expectLast(["upgrade", "UDID-1", "com.apple.CoreSimulator.SimRuntime.iOS-26-0"])
    }

    // MARK: - Apps

    @Test func install() throws {
        try simctl.install(udid: "UDID-1", appPath: "/tmp/My.app")
        expectLast(["install", "UDID-1", "/tmp/My.app"])
    }

    @Test func uninstall() throws {
        try simctl.uninstall(udid: "UDID-1", bundleID: "com.example.app")
        expectLast(["uninstall", "UDID-1", "com.example.app"])
    }

    @Test("launch composes flags before device and parses the PID")
    func launch() throws {
        runner.stub(stdout: "com.example.app: 4242\n")

        let pid = try simctl.launch(
            udid: "UDID-1",
            bundleID: "com.example.app",
            arguments: ["-flag", "value"],
            waitForDebugger: true,
            terminateRunningProcess: true
        )

        expectLast([
            "launch", "--wait-for-debugger", "--terminate-running-process",
            "UDID-1", "com.example.app", "-flag", "value",
        ])
        #expect(pid == 4242)
    }

    @Test("launch with console streams interactively")
    func launchWithConsole() throws {
        let pid = try simctl.launchWithConsole(
            udid: "UDID-1",
            bundleID: "com.example.app",
            arguments: [],
            waitForDebugger: false,
            terminateRunningProcess: false
        )

        expectLast(["launch", "--console-pty", "UDID-1", "com.example.app"])
        #expect(pid == nil)
    }

    @Test func terminate() throws {
        try simctl.terminate(udid: "UDID-1", bundleID: "com.example.app")
        expectLast(["terminate", "UDID-1", "com.example.app"])
    }

    @Test("listApps returns raw output for downstream formatting")
    func listApps() throws {
        runner.stub(stdout: "{ apps }")

        let output = try simctl.listApps(udid: "UDID-1")

        expectLast(["listapps", "UDID-1"])
        #expect(output == "{ apps }")
    }

    @Test func appInfo() throws {
        runner.stub(stdout: "{ info }")
        _ = try simctl.appInfo(udid: "UDID-1", bundleID: "com.example.app")
        expectLast(["appinfo", "UDID-1", "com.example.app"])
    }

    @Test("appContainer trims the returned path")
    func appContainer() throws {
        runner.stub(stdout: "/path/to/container\n")

        let path = try simctl.appContainer(udid: "UDID-1", bundleID: "com.example.app", container: "data")

        expectLast(["get_app_container", "UDID-1", "com.example.app", "data"])
        #expect(path == "/path/to/container")
    }

    @Test func installAppData() throws {
        try simctl.installAppData(udid: "UDID-1", path: "/tmp/data.xcappdata")
        expectLast(["install_app_data", "UDID-1", "/tmp/data.xcappdata"])
    }

    // MARK: - IO

    @Test("screenshot composes optional flags before the output path")
    func screenshot() throws {
        try simctl.screenshot(
            udid: "UDID-1",
            outputPath: "/tmp/shot.png",
            type: "jpeg",
            display: "internal",
            mask: "black"
        )

        expectLast([
            "io", "UDID-1", "screenshot",
            "--type=jpeg", "--display=internal", "--mask=black",
            "/tmp/shot.png",
        ])
    }

    @Test("screenshot omits absent flags")
    func screenshotMinimal() throws {
        try simctl.screenshot(udid: "UDID-1", outputPath: "/tmp/shot.png")
        expectLast(["io", "UDID-1", "screenshot", "/tmp/shot.png"])
    }

    @Test("recordVideo runs interactively so Ctrl-C finalizes the file")
    func recordVideo() throws {
        let code = try simctl.recordVideo(
            udid: "UDID-1",
            outputPath: "/tmp/video.mp4",
            codec: "h264",
            display: nil,
            mask: nil,
            force: true
        )

        expectLast(["io", "UDID-1", "recordVideo", "--codec=h264", "--force", "/tmp/video.mp4"])
        #expect(code == 0)
    }

    // MARK: - System

    @Test func openURL() throws {
        try simctl.openURL(udid: "UDID-1", url: "https://example.com")
        expectLast(["openurl", "UDID-1", "https://example.com"])
    }

    @Test func addMedia() throws {
        try simctl.addMedia(udid: "UDID-1", paths: ["/tmp/a.png", "/tmp/b.mov"])
        expectLast(["addmedia", "UDID-1", "/tmp/a.png", "/tmp/b.mov"])
    }

    @Test("push with a payload file and target bundle")
    func push() throws {
        try simctl.push(udid: "UDID-1", bundleID: "com.example.app", payloadPath: "/tmp/payload.json")
        expectLast(["push", "UDID-1", "com.example.app", "/tmp/payload.json"])
    }

    @Test("push without bundle id (taken from payload) reading stdin")
    func pushStdin() throws {
        try simctl.push(udid: "UDID-1", bundleID: nil, payloadPath: "-")
        expectLast(["push", "UDID-1", "-"])
    }

    @Test func privacy() throws {
        try simctl.privacy(udid: "UDID-1", action: .grant, service: "photos", bundleID: "com.example.app")
        expectLast(["privacy", "UDID-1", "grant", "photos", "com.example.app"])
    }

    @Test("privacy reset works without a bundle id")
    func privacyReset() throws {
        try simctl.privacy(udid: "UDID-1", action: .reset, service: "all", bundleID: nil)
        expectLast(["privacy", "UDID-1", "reset", "all"])
    }

    @Test("status bar overrides emit flags in a stable order")
    func statusBarOverride() throws {
        var overrides = StatusBarOverrides()
        overrides.time = "9:41"
        overrides.dataNetwork = "5g"
        overrides.wifiBars = 3
        overrides.batteryState = "charged"
        overrides.batteryLevel = 100

        try simctl.statusBarOverride(udid: "UDID-1", overrides: overrides)

        expectLast([
            "status_bar", "UDID-1", "override",
            "--time", "9:41",
            "--dataNetwork", "5g",
            "--wifiBars", "3",
            "--batteryState", "charged",
            "--batteryLevel", "100",
        ])
    }

    @Test func statusBarClear() throws {
        try simctl.statusBarClear(udid: "UDID-1")
        expectLast(["status_bar", "UDID-1", "clear"])
    }

    @Test func statusBarList() throws {
        runner.stub(stdout: "overrides")
        _ = try simctl.statusBarList(udid: "UDID-1")
        expectLast(["status_bar", "UDID-1", "list"])
    }

    @Test("ui option set and get")
    func uiOption() throws {
        try simctl.setUIOption(udid: "UDID-1", option: "appearance", value: "dark")
        expectLast(["ui", "UDID-1", "appearance", "dark"])

        runner.stub(stdout: "dark\n")
        let value = try simctl.uiOption(udid: "UDID-1", option: "appearance")
        expectLast(["ui", "UDID-1", "appearance"])
        #expect(value == "dark")
    }

    @Test func getenv() throws {
        runner.stub(stdout: "/tmp/home\n")
        let value = try simctl.getenv(udid: "UDID-1", variable: "HOME")
        expectLast(["getenv", "UDID-1", "HOME"])
        #expect(value == "/tmp/home")
    }

    @Test func icloudSync() throws {
        try simctl.icloudSync(udid: "UDID-1")
        expectLast(["icloud_sync", "UDID-1"])
    }

    @Test("keychain actions with and without a path argument")
    func keychain() throws {
        try simctl.keychainAddRootCert(udid: "UDID-1", path: "/tmp/ca.pem")
        expectLast(["keychain", "UDID-1", "add-root-cert", "/tmp/ca.pem"])

        try simctl.keychainAddCert(udid: "UDID-1", path: "/tmp/cert.pem")
        expectLast(["keychain", "UDID-1", "add-cert", "/tmp/cert.pem"])

        try simctl.keychainReset(udid: "UDID-1")
        expectLast(["keychain", "UDID-1", "reset"])
    }

    // MARK: - Location

    @Test func locationSet() throws {
        try simctl.locationSet(udid: "UDID-1", latitude: 37.3349, longitude: -122.009)
        expectLast(["location", "UDID-1", "set", "37.3349,-122.009"])
    }

    @Test func locationClear() throws {
        try simctl.locationClear(udid: "UDID-1")
        expectLast(["location", "UDID-1", "clear"])
    }

    @Test func locationRun() throws {
        try simctl.locationRun(udid: "UDID-1", scenario: "City Bicycle Ride")
        expectLast(["location", "UDID-1", "run", "City Bicycle Ride"])
    }

    @Test func locationList() throws {
        runner.stub(stdout: "scenarios")
        _ = try simctl.locationList(udid: "UDID-1")
        expectLast(["location", "UDID-1", "list"])
    }

    // MARK: - Pasteboard

    @Test func pasteboard() throws {
        try simctl.pbcopy(udid: "UDID-1")
        expectLast(["pbcopy", "UDID-1"])

        runner.stub(stdout: "clipboard contents")
        let pasted = try simctl.pbpaste(udid: "UDID-1")
        expectLast(["pbpaste", "UDID-1"])
        #expect(pasted == "clipboard contents")

        try simctl.pbsync(source: "host", destination: "UDID-1")
        expectLast(["pbsync", "host", "UDID-1"])
    }

    // MARK: - Pairing

    @Test("pair returns the new pair UUID")
    func pair() throws {
        runner.stub(stdout: "PAIR-UUID\n")

        let uuid = try simctl.pair(watchUDID: "WATCH", phoneUDID: "PHONE")

        expectLast(["pair", "WATCH", "PHONE"])
        #expect(uuid == "PAIR-UUID")
    }

    @Test func unpair() throws {
        try simctl.unpair(pairUDID: "PAIR-UUID")
        expectLast(["unpair", "PAIR-UUID"])
    }

    @Test func pairActivate() throws {
        try simctl.pairActivate(pairUDID: "PAIR-UUID")
        expectLast(["pair_activate", "PAIR-UUID"])
    }

    // MARK: - Misc

    @Test func logverbose() throws {
        try simctl.logverbose(udid: "UDID-1", enabled: true)
        expectLast(["logverbose", "UDID-1", "enable"])

        try simctl.logverbose(udid: "UDID-1", enabled: false)
        expectLast(["logverbose", "UDID-1", "disable"])
    }

    @Test("spawn runs interactively for streaming output")
    func spawn() throws {
        _ = try simctl.spawn(udid: "UDID-1", executablePath: "/bin/ls", arguments: ["-la"])
        expectLast(["spawn", "UDID-1", "/bin/ls", "-la"])
    }

    @Test("diagnose runs interactively with options")
    func diagnose() throws {
        _ = try simctl.diagnose(outputPath: "/tmp/diag", allLogs: true, udids: ["A"])
        expectLast(["diagnose", "-b", "--output=/tmp/diag", "--all-logs", "--udid=A"])
    }

    @Test func runtimeList() throws {
        runner.stub(stdout: "runtimes")
        _ = try simctl.runtimeList()
        expectLast(["runtime", "list"])
    }

    @Test("runtime images requests JSON and parses installed builds")
    func runtimeImages() throws {
        runner.stub(stdout: RuntimeFixtures.runtimeListJSON)

        let images = try simctl.runtimeImages()

        expectLast(["runtime", "list", "-j"])
        #expect(images.count == 2)
        let ios = try #require(images.first { $0.build == "23F77" })
        #expect(ios.version == "26.5")
        #expect(ios.runtimeIdentifier == "com.apple.CoreSimulator.SimRuntime.iOS-26-5")
        #expect(ios.state == "Ready")
    }

    @Test func runtimeDelete() throws {
        try simctl.runtimeDelete(identifier: "ABC")
        expectLast(["runtime", "delete", "ABC"])
    }

    @Test("runtime delete by age supports dry runs")
    func runtimeDeleteUnused() throws {
        runner.stub(stdout: "deleted images\n")
        runner.stub(stdout: "would delete\n")

        _ = try simctl.runtimeDeleteUnused(days: 30, dryRun: false)
        expectLast(["runtime", "delete", "--notUsedSinceDays", "30"])

        let output = try simctl.runtimeDeleteUnused(days: 14, dryRun: true)
        expectLast(["runtime", "delete", "--notUsedSinceDays", "14", "--dry-run"])
        #expect(output == "would delete\n")
    }

    // MARK: - Device sets

    @Test("a custom device set prefixes every invocation with --set")
    func deviceSet() throws {
        let isolated = Simctl(runner: runner, deviceSet: "/tmp/ci-devices")

        try isolated.boot(udid: "UDID-1")

        #expect(runner.lastCommand == Command(
            executable: "/usr/bin/xcrun",
            arguments: ["simctl", "--set", "/tmp/ci-devices", "boot", "UDID-1"]
        ))
    }

    // MARK: - Failure propagation

    @Test("non-zero exits surface as CommandFailure")
    func failurePropagates() {
        runner.stub(stderr: "Invalid device: nope\n", exitCode: 164)

        #expect {
            try simctl.boot(udid: "nope")
        } throws: { error in
            (error as? CommandFailure)?.exitCode == 164
        }
    }
}
