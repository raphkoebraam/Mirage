import Foundation

/// Typed client for `xcrun simctl`. Each method maps 1:1 to a simctl
/// subcommand and is exercised by argv-contract tests; device resolution
/// (names, prefixes, "booted") happens in `DeviceResolver`, not here.
public struct Simctl: Sendable {
    private let runner: any CommandRunning
    private let deviceSet: String?

    /// - Parameter deviceSet: optional path to a custom CoreSimulator device
    ///   set (`simctl --set`), isolating all operations from the default set.
    public init(runner: any CommandRunning = ProcessCommandRunner(), deviceSet: String? = nil) {
        self.runner = runner
        self.deviceSet = deviceSet
    }

    // MARK: - Inventory

    public func list() throws -> SimulatorInventory {
        let output = try runner.runChecked(command(["list", "-j"]))
        return try SimulatorInventory(json: output.standardOutput)
    }

    // MARK: - Device lifecycle

    /// Returns the UDID of the created device.
    public func create(
        name: String,
        deviceTypeIdentifier: String,
        runtimeIdentifier: String?
    ) throws -> String {
        var arguments = ["create", name, deviceTypeIdentifier]
        if let runtimeIdentifier {
            arguments.append(runtimeIdentifier)
        }
        return try trimmed(runner.runChecked(command(arguments)))
    }

    public func boot(udid: String) throws {
        try runner.runChecked(command(["boot", udid]))
    }

    public func shutdown(udid: String) throws {
        try runner.runChecked(command(["shutdown", udid]))
    }

    public func shutdownAll() throws {
        try runner.runChecked(command(["shutdown", "all"]))
    }

    public func erase(udids: [String]) throws {
        try runner.runChecked(command(["erase"] + udids))
    }

    public func eraseAll() throws {
        try runner.runChecked(command(["erase", "all"]))
    }

    public func delete(udids: [String]) throws {
        try runner.runChecked(command(["delete"] + udids))
    }

    public func deleteUnavailable() throws {
        try runner.runChecked(command(["delete", "unavailable"]))
    }

    public func deleteAll() throws {
        try runner.runChecked(command(["delete", "all"]))
    }

    /// Returns the UDID of the cloned device.
    public func clone(udid: String, newName: String) throws -> String {
        try trimmed(runner.runChecked(command(["clone", udid, newName])))
    }

    public func rename(udid: String, to name: String) throws {
        try runner.runChecked(command(["rename", udid, name]))
    }

    public func upgrade(udid: String, runtimeIdentifier: String) throws {
        try runner.runChecked(command(["upgrade", udid, runtimeIdentifier]))
    }

    // MARK: - Apps

    public func install(udid: String, appPath: String) throws {
        try runner.runChecked(command(["install", udid, appPath]))
    }

    public func uninstall(udid: String, bundleID: String) throws {
        try runner.runChecked(command(["uninstall", udid, bundleID]))
    }

    /// Launches an app and returns its PID (parsed from simctl's
    /// "bundle-id: <pid>" output).
    public func launch(
        udid: String,
        bundleID: String,
        arguments: [String] = [],
        waitForDebugger: Bool = false,
        terminateRunningProcess: Bool = false
    ) throws -> Int? {
        var args = ["launch"]
        if waitForDebugger { args.append("--wait-for-debugger") }
        if terminateRunningProcess { args.append("--terminate-running-process") }
        args += [udid, bundleID] + arguments
        let output = try runner.runChecked(command(args))
        return parsePID(from: output.standardOutput)
    }

    /// Launches an app with its console attached to the terminal.
    /// Returns nil (no PID is parseable in streaming mode).
    public func launchWithConsole(
        udid: String,
        bundleID: String,
        arguments: [String] = [],
        waitForDebugger: Bool = false,
        terminateRunningProcess: Bool = false
    ) throws -> Int? {
        var args = ["launch"]
        if waitForDebugger { args.append("--wait-for-debugger") }
        if terminateRunningProcess { args.append("--terminate-running-process") }
        args.append("--console-pty")
        args += [udid, bundleID] + arguments
        _ = try runner.runInteractive(command(args))
        return nil
    }

    public func terminate(udid: String, bundleID: String) throws {
        try runner.runChecked(command(["terminate", udid, bundleID]))
    }

    public func listApps(udid: String) throws -> String {
        try runner.runChecked(command(["listapps", udid])).standardOutput
    }

    public func appInfo(udid: String, bundleID: String) throws -> String {
        try runner.runChecked(command(["appinfo", udid, bundleID])).standardOutput
    }

    public func appContainer(udid: String, bundleID: String, container: String? = nil) throws -> String {
        var arguments = ["get_app_container", udid, bundleID]
        if let container {
            arguments.append(container)
        }
        return try trimmed(runner.runChecked(command(arguments)))
    }

    public func installAppData(udid: String, path: String) throws {
        try runner.runChecked(command(["install_app_data", udid, path]))
    }

    // MARK: - IO

    public func screenshot(
        udid: String,
        outputPath: String,
        type: String? = nil,
        display: String? = nil,
        mask: String? = nil
    ) throws {
        var arguments = ["io", udid, "screenshot"]
        if let type { arguments.append("--type=\(type)") }
        if let display { arguments.append("--display=\(display)") }
        if let mask { arguments.append("--mask=\(mask)") }
        arguments.append(outputPath)
        try runner.runChecked(command(arguments))
    }

    /// Records until the user interrupts with Ctrl-C; runs interactively so
    /// SIGINT reaches simctl and the video file is finalized.
    public func recordVideo(
        udid: String,
        outputPath: String,
        codec: String? = nil,
        display: String? = nil,
        mask: String? = nil,
        force: Bool = false
    ) throws -> Int32 {
        var arguments = ["io", udid, "recordVideo"]
        if let codec { arguments.append("--codec=\(codec)") }
        if let display { arguments.append("--display=\(display)") }
        if let mask { arguments.append("--mask=\(mask)") }
        if force { arguments.append("--force") }
        arguments.append(outputPath)
        return try runner.runInteractive(command(arguments))
    }

    // MARK: - System

    public func openURL(udid: String, url: String) throws {
        try runner.runChecked(command(["openurl", udid, url]))
    }

    public func addMedia(udid: String, paths: [String]) throws {
        try runner.runChecked(command(["addmedia", udid] + paths))
    }

    /// `payloadPath` may be "-" to read the payload from stdin; `bundleID`
    /// may be nil when the payload contains "Simulator Target Bundle".
    public func push(udid: String, bundleID: String?, payloadPath: String) throws {
        var arguments = ["push", udid]
        if let bundleID {
            arguments.append(bundleID)
        }
        arguments.append(payloadPath)
        try runner.runChecked(command(arguments))
    }

    public enum PrivacyAction: String, CaseIterable, Sendable {
        case grant, revoke, reset
    }

    public func privacy(udid: String, action: PrivacyAction, service: String, bundleID: String?) throws {
        var arguments = ["privacy", udid, action.rawValue, service]
        if let bundleID {
            arguments.append(bundleID)
        }
        try runner.runChecked(command(arguments))
    }

    public func statusBarOverride(udid: String, overrides: StatusBarOverrides) throws {
        try runner.runChecked(command(["status_bar", udid, "override"] + overrides.flags))
    }

    public func statusBarClear(udid: String) throws {
        try runner.runChecked(command(["status_bar", udid, "clear"]))
    }

    public func statusBarList(udid: String) throws -> String {
        try runner.runChecked(command(["status_bar", udid, "list"])).standardOutput
    }

    public func setUIOption(udid: String, option: String, value: String) throws {
        try runner.runChecked(command(["ui", udid, option, value]))
    }

    public func uiOption(udid: String, option: String) throws -> String {
        try trimmed(runner.runChecked(command(["ui", udid, option])))
    }

    public func getenv(udid: String, variable: String) throws -> String {
        try trimmed(runner.runChecked(command(["getenv", udid, variable])))
    }

    public func icloudSync(udid: String) throws {
        try runner.runChecked(command(["icloud_sync", udid]))
    }

    public func keychainAddRootCert(udid: String, path: String) throws {
        try runner.runChecked(command(["keychain", udid, "add-root-cert", path]))
    }

    public func keychainAddCert(udid: String, path: String) throws {
        try runner.runChecked(command(["keychain", udid, "add-cert", path]))
    }

    public func keychainReset(udid: String) throws {
        try runner.runChecked(command(["keychain", udid, "reset"]))
    }

    // MARK: - Location

    public func locationSet(udid: String, latitude: Double, longitude: Double) throws {
        try runner.runChecked(command(["location", udid, "set", "\(latitude),\(longitude)"]))
    }

    public func locationClear(udid: String) throws {
        try runner.runChecked(command(["location", udid, "clear"]))
    }

    public func locationRun(udid: String, scenario: String) throws {
        try runner.runChecked(command(["location", udid, "run", scenario]))
    }

    public func locationList(udid: String) throws -> String {
        try runner.runChecked(command(["location", udid, "list"])).standardOutput
    }

    // MARK: - Pasteboard

    public func pbcopy(udid: String) throws {
        try runner.runChecked(command(["pbcopy", udid]))
    }

    public func pbpaste(udid: String) throws -> String {
        try runner.runChecked(command(["pbpaste", udid])).standardOutput
    }

    /// Either side may be a device UDID or the literal "host".
    public func pbsync(source: String, destination: String) throws {
        try runner.runChecked(command(["pbsync", source, destination]))
    }

    // MARK: - Pairing

    /// Returns the UUID of the new pair.
    public func pair(watchUDID: String, phoneUDID: String) throws -> String {
        try trimmed(runner.runChecked(command(["pair", watchUDID, phoneUDID])))
    }

    public func unpair(pairUDID: String) throws {
        try runner.runChecked(command(["unpair", pairUDID]))
    }

    public func pairActivate(pairUDID: String) throws {
        try runner.runChecked(command(["pair_activate", pairUDID]))
    }

    // MARK: - Misc

    public func logverbose(udid: String, enabled: Bool) throws {
        try runner.runChecked(command(["logverbose", udid, enabled ? "enable" : "disable"]))
    }

    public func spawn(udid: String, executablePath: String, arguments: [String]) throws -> Int32 {
        try runner.runInteractive(command(["spawn", udid, executablePath] + arguments))
    }

    /// `-b` skips the privacy-warning prompt so diagnose can run unattended.
    public func diagnose(outputPath: String?, allLogs: Bool, udids: [String]) throws -> Int32 {
        var arguments = ["diagnose", "-b"]
        if let outputPath { arguments.append("--output=\(outputPath)") }
        if allLogs { arguments.append("--all-logs") }
        arguments += udids.map { "--udid=\($0)" }
        return try runner.runInteractive(command(arguments))
    }

    public func runtimeList() throws -> String {
        try runner.runChecked(command(["runtime", "list"])).standardOutput
    }

    /// Installed runtime disk images with their builds, for matching
    /// against the download catalog.
    public func runtimeImages() throws -> [RuntimeImage] {
        let output = try runner.runChecked(command(["runtime", "list", "-j"]))
        return try RuntimeImage.parse(json: output.standardOutput)
    }

    public func runtimeDelete(identifier: String) throws {
        try runner.runChecked(command(["runtime", "delete", identifier]))
    }

    /// Deletes runtime disk images unused for at least `days` days.
    /// Returns simctl's report of the affected images.
    public func runtimeDeleteUnused(days: Int, dryRun: Bool) throws -> String {
        var arguments = ["runtime", "delete", "--notUsedSinceDays", String(days)]
        if dryRun {
            arguments.append("--dry-run")
        }
        return try runner.runChecked(command(arguments)).standardOutput
    }

    // MARK: - Helpers

    private func command(_ arguments: [String]) -> Command {
        let setPrefix = deviceSet.map { ["--set", $0] } ?? []
        return Command(executable: "/usr/bin/xcrun", arguments: ["simctl"] + setPrefix + arguments)
    }

    private func trimmed(_ output: CommandOutput) -> String {
        output.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parsePID(from output: String) -> Int? {
        guard let colon = output.lastIndex(of: ":") else { return nil }
        return Int(output[output.index(after: colon)...].trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

/// Typed `status_bar override` flags; emitted in declaration order so the
/// produced argv is deterministic.
public struct StatusBarOverrides: Equatable, Sendable {
    public var time: String?
    public var dataNetwork: String?
    public var wifiMode: String?
    public var wifiBars: Int?
    public var cellularMode: String?
    public var cellularBars: Int?
    public var operatorName: String?
    public var batteryState: String?
    public var batteryLevel: Int?

    public init() {}

    public var isEmpty: Bool {
        flags.isEmpty
    }

    public var flags: [String] {
        var result: [String] = []
        func add(_ flag: String, _ value: String?) {
            if let value {
                result += [flag, value]
            }
        }
        add("--time", time)
        add("--dataNetwork", dataNetwork)
        add("--wifiMode", wifiMode)
        add("--wifiBars", wifiBars.map(String.init))
        add("--cellularMode", cellularMode)
        add("--cellularBars", cellularBars.map(String.init))
        add("--operatorName", operatorName)
        add("--batteryState", batteryState)
        add("--batteryLevel", batteryLevel.map(String.init))
        return result
    }
}
