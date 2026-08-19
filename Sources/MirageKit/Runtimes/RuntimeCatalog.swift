import Foundation

/// A simulator runtime Apple offers for download, as listed in the
/// `index2.dvtdownloadableindex` feed that Xcode's Components pane and
/// `xcodebuild -downloadPlatform` consult.
public struct DownloadableRuntime: Equatable, Sendable, Codable {
    /// Display name, e.g. "iOS 26.5 Simulator Runtime".
    public let name: String
    /// Normalized platform: iOS, watchOS, tvOS, or visionOS.
    public let platform: String
    /// Marketing version, e.g. "26.5".
    public let version: String
    /// Build, e.g. "23F77"; matches `simctl runtime list` builds.
    public let build: String
    /// Download size in bytes.
    public let fileSize: Int64
    /// CPU architectures the image supports; empty when the feed omits them.
    public let architectures: [String]
    /// Betas and release candidates.
    public let isPrerelease: Bool

    public init(
        name: String,
        platform: String,
        version: String,
        build: String,
        fileSize: Int64,
        architectures: [String],
        isPrerelease: Bool
    ) {
        self.name = name
        self.platform = platform
        self.version = version
        self.build = build
        self.fileSize = fileSize
        self.architectures = architectures
        self.isPrerelease = isPrerelease
    }
}

/// Parsed download feed, reduced to the runtimes `xcodebuild -downloadPlatform`
/// can install on this machine.
public struct RuntimeCatalog: Equatable, Sendable {
    public let runtimes: [DownloadableRuntime]

    public init(runtimes: [DownloadableRuntime]) {
        self.runtimes = runtimes
    }

    /// - Parameters:
    ///   - plist: raw `index2.dvtdownloadableindex` contents.
    ///   - hostArchitecture: "arm64" or "x86_64"; picks between architecture
    ///     variants of the same build.
    public init(plist: Data, hostArchitecture: String) throws {
        let index = try PropertyListDecoder().decode(Index.self, from: plist)

        // Only mobileAsset entries are fetchable through xcodebuild; the
        // legacy .dmg entries predate Xcode 14's runtime packaging.
        let candidates = index.downloadables.filter { entry in
            entry.category == "simulator" && entry.downloadMethod == "mobileAsset"
        }

        struct BuildKey: Hashable {
            let platform: String
            let build: String
        }

        var chosen: [BuildKey: FeedDownloadable] = [:]
        for entry in candidates {
            let key = BuildKey(platform: entry.platform, build: entry.simulatorVersion.buildUpdate)
            guard let current = chosen[key] else {
                chosen[key] = entry
                continue
            }
            if Self.prefers(entry, over: current, hostArchitecture: hostArchitecture) {
                chosen[key] = entry
            }
        }

        runtimes = chosen.values
            .map { entry in
                DownloadableRuntime(
                    name: entry.name,
                    platform: Self.platformName(entry.platform),
                    version: entry.simulatorVersion.version,
                    build: entry.simulatorVersion.buildUpdate,
                    fileSize: entry.fileSize ?? 0,
                    architectures: entry.architectures ?? [],
                    isPrerelease: Self.isPrerelease(entry.name)
                )
            }
            .sorted { lhs, rhs in
                if lhs.platform != rhs.platform {
                    return Self.platformRank(lhs.platform) < Self.platformRank(rhs.platform)
                }
                if lhs.version != rhs.version {
                    return lhs.version.compareNumerically(to: rhs.version) == .orderedDescending
                }
                // Same marketing version: the release outranks its betas,
                // then newer builds first.
                if lhs.isPrerelease != rhs.isPrerelease {
                    return !lhs.isPrerelease
                }
                return lhs.build.compare(rhs.build, options: .numeric) == .orderedDescending
            }
    }

    /// Runtimes for one platform (case-insensitive: "ios", "iOS").
    public func runtimes(platform: String) -> [DownloadableRuntime] {
        runtimes.filter { $0.platform.caseInsensitiveCompare(platform) == .orderedSame }
    }

    // MARK: - Selection rules

    /// An arm64-only image is smaller than the universal one and is what
    /// Apple silicon hosts receive; Intel hosts need the universal image.
    private static func prefers(
        _ candidate: FeedDownloadable,
        over current: FeedDownloadable,
        hostArchitecture: String
    ) -> Bool {
        let candidateArchs = candidate.architectures ?? []
        let currentArchs = current.architectures ?? []
        let wantsArmOnly = hostArchitecture == "arm64"
        let candidateIsArmOnly = candidateArchs == ["arm64"]
        let currentIsArmOnly = currentArchs == ["arm64"]
        if candidateIsArmOnly != currentIsArmOnly {
            return candidateIsArmOnly == wantsArmOnly
        }
        return false
    }

    private static func platformName(_ identifier: String) -> String {
        switch identifier {
        case "com.apple.platform.iphoneos": "iOS"
        case "com.apple.platform.watchos": "watchOS"
        case "com.apple.platform.appletvos": "tvOS"
        case "com.apple.platform.xros": "visionOS"
        default: identifier.replacingOccurrences(of: "com.apple.platform.", with: "")
        }
    }

    private static func platformRank(_ platform: String) -> Int {
        ["iOS", "watchOS", "tvOS", "visionOS"].firstIndex(of: platform) ?? Int.max
    }

    private static func isPrerelease(_ name: String) -> Bool {
        let lowered = name.lowercased()
        return lowered.contains("beta") || lowered.contains("release candidate")
    }

    // MARK: - Feed schema

    private struct Index: Decodable {
        let downloadables: [FeedDownloadable]
    }
}

/// One entry of the download feed; only the keys mirage reads.
private struct FeedDownloadable: Decodable {
    let name: String
    let platform: String
    let category: String?
    let downloadMethod: String?
    let fileSize: Int64?
    let architectures: [String]?
    let simulatorVersion: FeedSimulatorVersion
}

private struct FeedSimulatorVersion: Decodable {
    let buildUpdate: String
    let version: String
}

/// Downloads the feed with curl (the only OS seam stays `CommandRunning`).
public struct RuntimeCatalogFetcher: Sendable {
    public static let indexURL =
        "https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex"

    private let runner: any CommandRunning
    private let hostArchitecture: String

    public init(
        runner: any CommandRunning = ProcessCommandRunner(),
        hostArchitecture: String = Self.currentArchitecture
    ) {
        self.runner = runner
        self.hostArchitecture = hostArchitecture
    }

    public func fetch() throws -> RuntimeCatalog {
        let output = try runner.runChecked(Command(
            executable: "/usr/bin/curl",
            arguments: ["-fsSL", "--max-time", "60", Self.indexURL]
        ))
        return try RuntimeCatalog(plist: Data(output.standardOutput.utf8), hostArchitecture: hostArchitecture)
    }

    public static var currentArchitecture: String {
        #if arch(arm64)
            "arm64"
        #else
            "x86_64"
        #endif
    }
}
