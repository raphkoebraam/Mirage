/// Client for the `xcodebuild` operations mirage needs, currently just
/// runtime platform downloads.
public struct Xcodebuild: Sendable {
    private let runner: any CommandRunning

    public init(runner: any CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    /// Downloads (or updates) a simulator runtime. Runs interactively so
    /// xcodebuild's progress output reaches the terminal; a nil
    /// `buildVersion` fetches the latest.
    @discardableResult
    public func downloadPlatform(_ platform: String, buildVersion: String?) throws -> Int32 {
        var arguments = ["xcodebuild", "-downloadPlatform", platform]
        if let buildVersion {
            arguments += ["-buildVersion", buildVersion]
        }
        return try runner.runInteractive(Command(executable: "/usr/bin/xcrun", arguments: arguments))
    }
}
