/// Curated payloads for runtime catalog tests: a trimmed
/// `index2.dvtdownloadableindex` (Apple's simulator download feed) and a
/// `simctl runtime list -j` report.
public enum RuntimeFixtures {
    /// Six downloadables covering the edge cases the parser must handle:
    /// - iOS 26.5: one universal and one arm64-only entry for the same build
    /// - iOS 26.5 beta 4: a pre-release
    /// - iOS 27.0 Release Candidate: a pre-release without "beta" in its name
    /// - watchOS 26.4: no `architectures` key at all
    /// - iOS 15.5: legacy `diskImage` entry that `-downloadPlatform` cannot fetch
    public static let downloadableIndexPlist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>version</key>
      <integer>2</integer>
      <key>downloadables</key>
      <array>
        <dict>
          <key>architectures</key>
          <array><string>arm64</string><string>x86_64</string></array>
          <key>category</key>
          <string>simulator</string>
          <key>contentType</key>
          <string>cryptexDiskImage</string>
          <key>downloadMethod</key>
          <string>mobileAsset</string>
          <key>fileSize</key>
          <integer>10603482980</integer>
          <key>identifier</key>
          <string>00000000-0000-0000-0000-000000000001</string>
          <key>name</key>
          <string>iOS 26.5 Simulator Runtime</string>
          <key>platform</key>
          <string>com.apple.platform.iphoneos</string>
          <key>simulatorVersion</key>
          <dict>
            <key>buildUpdate</key>
            <string>23F77</string>
            <key>version</key>
            <string>26.5</string>
          </dict>
          <key>version</key>
          <string>26.5.0.0</string>
        </dict>
        <dict>
          <key>architectures</key>
          <array><string>arm64</string></array>
          <key>category</key>
          <string>simulator</string>
          <key>contentType</key>
          <string>cryptexDiskImage</string>
          <key>downloadMethod</key>
          <string>mobileAsset</string>
          <key>fileSize</key>
          <integer>8522901359</integer>
          <key>identifier</key>
          <string>00000000-0000-0000-0000-000000000002</string>
          <key>name</key>
          <string>iOS 26.5 Simulator Runtime</string>
          <key>platform</key>
          <string>com.apple.platform.iphoneos</string>
          <key>simulatorVersion</key>
          <dict>
            <key>buildUpdate</key>
            <string>23F77</string>
            <key>version</key>
            <string>26.5</string>
          </dict>
          <key>version</key>
          <string>26.5.0.0</string>
        </dict>
        <dict>
          <key>architectures</key>
          <array><string>arm64</string></array>
          <key>category</key>
          <string>simulator</string>
          <key>contentType</key>
          <string>cryptexDiskImage</string>
          <key>downloadMethod</key>
          <string>mobileAsset</string>
          <key>fileSize</key>
          <integer>8522901000</integer>
          <key>identifier</key>
          <string>00000000-0000-0000-0000-000000000003</string>
          <key>name</key>
          <string>iOS 26.5 beta 4 Simulator Runtime</string>
          <key>platform</key>
          <string>com.apple.platform.iphoneos</string>
          <key>simulatorVersion</key>
          <dict>
            <key>buildUpdate</key>
            <string>23F5069b</string>
            <key>version</key>
            <string>26.5</string>
          </dict>
          <key>version</key>
          <string>26.5.0.4</string>
        </dict>
        <dict>
          <key>architectures</key>
          <array><string>arm64</string></array>
          <key>category</key>
          <string>simulator</string>
          <key>contentType</key>
          <string>cryptexDiskImage</string>
          <key>downloadMethod</key>
          <string>mobileAsset</string>
          <key>fileSize</key>
          <integer>7986040832</integer>
          <key>identifier</key>
          <string>00000000-0000-0000-0000-000000000004</string>
          <key>name</key>
          <string>iOS 27.0 Release Candidate Simulator Runtime</string>
          <key>platform</key>
          <string>com.apple.platform.iphoneos</string>
          <key>simulatorVersion</key>
          <dict>
            <key>buildUpdate</key>
            <string>24A5408d</string>
            <key>version</key>
            <string>27.0</string>
          </dict>
          <key>version</key>
          <string>27.0.0.6</string>
        </dict>
        <dict>
          <key>category</key>
          <string>simulator</string>
          <key>contentType</key>
          <string>cryptexDiskImage</string>
          <key>downloadMethod</key>
          <string>mobileAsset</string>
          <key>fileSize</key>
          <integer>3931694170</integer>
          <key>identifier</key>
          <string>00000000-0000-0000-0000-000000000005</string>
          <key>name</key>
          <string>watchOS 26.4 Simulator Runtime</string>
          <key>platform</key>
          <string>com.apple.platform.watchos</string>
          <key>simulatorVersion</key>
          <dict>
            <key>buildUpdate</key>
            <string>23T239</string>
            <key>version</key>
            <string>26.4</string>
          </dict>
          <key>version</key>
          <string>26.4.0.0</string>
        </dict>
        <dict>
          <key>category</key>
          <string>simulator</string>
          <key>contentType</key>
          <string>diskImage</string>
          <key>fileSize</key>
          <integer>6000000000</integer>
          <key>identifier</key>
          <string>00000000-0000-0000-0000-000000000006</string>
          <key>name</key>
          <string>iOS 15.5 Simulator Runtime</string>
          <key>platform</key>
          <string>com.apple.platform.iphoneos</string>
          <key>simulatorVersion</key>
          <dict>
            <key>buildUpdate</key>
            <string>19F70</string>
            <key>version</key>
            <string>15.5</string>
          </dict>
          <key>source</key>
          <string>https://download.developer.apple.com/iOS_15.5_Simulator_Runtime.dmg</string>
          <key>version</key>
          <string>15.5.0.0</string>
        </dict>
      </array>
    </dict>
    </plist>
    """

    /// Two installed images: iOS 26.5 (23F77) and watchOS 26.4 (23T239).
    public static let runtimeListJSON = """
    {
      "F5C0D8C6-39E5-42F6-A211-22892CFF099C" : {
        "build" : "23F77",
        "deletable" : true,
        "identifier" : "F5C0D8C6-39E5-42F6-A211-22892CFF099C",
        "kind" : "Patchable Cryptex Disk Image",
        "platformIdentifier" : "com.apple.platform.iphonesimulator",
        "runtimeIdentifier" : "com.apple.CoreSimulator.SimRuntime.iOS-26-5",
        "signatureState" : "Verified",
        "sizeBytes" : 8014773567,
        "state" : "Ready",
        "version" : "26.5"
      },
      "7FA94CC6-EA5D-4069-ADF8-17BC943A0CC2" : {
        "build" : "23T239",
        "deletable" : true,
        "identifier" : "7FA94CC6-EA5D-4069-ADF8-17BC943A0CC2",
        "kind" : "Patchable Cryptex Disk Image",
        "platformIdentifier" : "com.apple.platform.watchsimulator",
        "runtimeIdentifier" : "com.apple.CoreSimulator.SimRuntime.watchOS-26-4",
        "signatureState" : "Verified",
        "sizeBytes" : 3931694170,
        "state" : "Ready",
        "version" : "26.4"
      }
    }
    """
}
