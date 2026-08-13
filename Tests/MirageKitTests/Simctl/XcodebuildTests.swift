import MirageKit
import MirageKitTesting
import Testing

@Suite("Xcodebuild")
struct XcodebuildTests {
    let runner = MockCommandRunner()

    @Test("downloads the latest runtime for a platform")
    func downloadLatest() throws {
        let xcodebuild = Xcodebuild(runner: runner)

        _ = try xcodebuild.downloadPlatform("iOS", buildVersion: nil)

        #expect(runner.lastCommand == Command(
            executable: "/usr/bin/xcrun",
            arguments: ["xcodebuild", "-downloadPlatform", "iOS"]
        ))
    }

    @Test("downloads a specific runtime version")
    func downloadVersion() throws {
        let xcodebuild = Xcodebuild(runner: runner)

        _ = try xcodebuild.downloadPlatform("watchOS", buildVersion: "26.2")

        #expect(runner.lastCommand == Command(
            executable: "/usr/bin/xcrun",
            arguments: ["xcodebuild", "-downloadPlatform", "watchOS", "-buildVersion", "26.2"]
        ))
    }
}
