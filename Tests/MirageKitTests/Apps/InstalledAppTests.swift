import MirageKit
import Testing

@Suite("InstalledApp parsing")
struct InstalledAppTests {
    /// Condensed real `simctl listapps` output (openStep plist).
    static let sample = """
    {
        "com.apple.Bridge" =     {
            ApplicationType = System;
            Bundle = "file:///.../Bridge.app/";
            CFBundleDisplayName = Watch;
            CFBundleExecutable = Bridge;
            CFBundleIdentifier = "com.apple.Bridge";
            CFBundleName = Watch;
            CFBundleVersion = "1.0";
            Path = "/Library/Runtimes/iOS 26.5.simruntime/Applications/Bridge.app";
            SBAppTags =         (
                "watch-companion"
            );
        };
        "com.example.myapp" =     {
            ApplicationType = User;
            CFBundleDisplayName = "My App";
            CFBundleExecutable = MyApp;
            CFBundleIdentifier = "com.example.myapp";
            CFBundleVersion = "42";
            DataContainer = "file:///Users/tester/data/Containers/Data/Application/AAA/";
            Path = "/Users/tester/Devices/X/data/Containers/Bundle/Application/BBB/MyApp.app";
        };
    }
    """

    @Test("parses bundle id, name, type, version, and path")
    func parsesApps() throws {
        let apps = try InstalledApp.parse(listappsOutput: Self.sample)

        #expect(apps.count == 2)

        let myApp = try #require(apps.first { $0.bundleID == "com.example.myapp" })
        #expect(myApp.displayName == "My App")
        #expect(myApp.applicationType == "User")
        #expect(myApp.version == "42")
        #expect(myApp.path?.hasSuffix("MyApp.app") == true)
    }

    @Test("sorts user apps before system apps, then by name")
    func ordering() throws {
        let apps = try InstalledApp.parse(listappsOutput: Self.sample)

        #expect(apps.map(\.bundleID) == ["com.example.myapp", "com.apple.Bridge"])
    }

    @Test("throws on unparseable output")
    func malformed() {
        #expect(throws: (any Error).self) {
            _ = try InstalledApp.parse(listappsOutput: "not a plist at all {{{")
        }
    }
}
