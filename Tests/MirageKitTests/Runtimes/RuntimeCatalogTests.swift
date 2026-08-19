import Foundation
import MirageKit
import MirageKitTesting
import Testing

@Suite("RuntimeCatalog")
struct RuntimeCatalogTests {
    private func catalog(hostArchitecture: String = "arm64") throws -> RuntimeCatalog {
        try RuntimeCatalog(
            plist: Data(RuntimeFixtures.downloadableIndexPlist.utf8),
            hostArchitecture: hostArchitecture
        )
    }

    @Test("keeps only runtimes that xcodebuild -downloadPlatform can fetch")
    func filtersLegacyImages() throws {
        let runtimes = try catalog().runtimes

        #expect(!runtimes.contains { $0.version == "15.5" })
    }

    @Test("collapses architecture variants of the same build, preferring the host's")
    func dedupesByBuild() throws {
        let arm = try catalog(hostArchitecture: "arm64").runtimes.filter { $0.build == "23F77" }
        let intel = try catalog(hostArchitecture: "x86_64").runtimes.filter { $0.build == "23F77" }

        #expect(arm.count == 1)
        #expect(arm.first?.fileSize == 8_522_901_359)
        #expect(intel.count == 1)
        #expect(intel.first?.fileSize == 10_603_482_980)
    }

    @Test("normalizes platform identifiers and marks pre-releases")
    func platformsAndPrerelease() throws {
        let runtimes = try catalog().runtimes

        let ios = try #require(runtimes.first { $0.build == "23F77" })
        #expect(ios.platform == "iOS")
        #expect(ios.name == "iOS 26.5 Simulator Runtime")
        #expect(!ios.isPrerelease)

        let beta = try #require(runtimes.first { $0.build == "23F5069b" })
        #expect(beta.isPrerelease)

        let candidate = try #require(runtimes.first { $0.build == "24A5408d" })
        #expect(candidate.isPrerelease)

        let watch = try #require(runtimes.first { $0.build == "23T239" })
        #expect(watch.platform == "watchOS")
        #expect(watch.architectures.isEmpty)
    }

    @Test("sorts by platform, then newest version first")
    func ordering() throws {
        let builds = try catalog().runtimes.map(\.build)

        #expect(builds == ["24A5408d", "23F77", "23F5069b", "23T239"])
    }

    @Test("filters by platform case-insensitively")
    func platformFilter() throws {
        let runtimes = try catalog().runtimes(platform: "watchos")

        #expect(runtimes.map(\.build) == ["23T239"])
    }

    @Test("rejects payloads that are not a downloadable index")
    func rejectsGarbage() {
        #expect(throws: (any Error).self) {
            try RuntimeCatalog(plist: Data("not a plist".utf8), hostArchitecture: "arm64")
        }
    }
}

@Suite("RuntimeCatalogFetcher")
struct RuntimeCatalogFetcherTests {
    @Test("downloads Apple's index over curl and parses it")
    func fetches() throws {
        let runner = MockCommandRunner()
        runner.stub(stdout: RuntimeFixtures.downloadableIndexPlist)

        let catalog = try RuntimeCatalogFetcher(runner: runner, hostArchitecture: "arm64").fetch()

        #expect(runner.lastCommand == Command(
            executable: "/usr/bin/curl",
            arguments: ["-fsSL", "--max-time", "60", RuntimeCatalogFetcher.indexURL]
        ))
        #expect(catalog.runtimes.count == 4)
    }
}
