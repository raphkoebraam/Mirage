import ArgumentParser
import MirageKitTesting
import Testing
@testable import MirageCLI

@Suite("mirage runtime available")
struct RuntimeAvailableCommandTests {
    let harness = CLIHarness()

    private func stubFeedAndImages() {
        harness.runner.stub(stdout: RuntimeFixtures.downloadableIndexPlist)
        harness.runner.stub(stdout: RuntimeFixtures.runtimeListJSON)
    }

    @Test("lists stable runtimes newest first and marks installed builds")
    func listsStable() async throws {
        stubFeedAndImages()

        try await harness.run(["runtime", "available"])

        #expect(harness.runner.executed.first?.executable == "/usr/bin/curl")
        #expect(harness.lastArguments == ["runtime", "list", "-j"])

        let table = try #require(harness.ui.tables.first)
        #expect(table.headers == ["Platform", "Version", "Build", "Size", "Status"])
        #expect(table.rows.map { [$0[0], $0[1], $0[2], $0[4]] } == [
            ["iOS", "26.5", "23F77", "installed"],
            ["watchOS", "26.4", "23T239", "installed"],
        ])
    }

    @Test("--prerelease includes betas and release candidates")
    func prerelease() async throws {
        stubFeedAndImages()

        try await harness.run(["runtime", "available", "--prerelease"])

        let table = try #require(harness.ui.tables.first)
        #expect(table.rows.map { $0[2] } == ["24A5408d", "23F77", "23F5069b", "23T239"])
        #expect(table.rows.first?[4] == "available")
    }

    @Test("--platform narrows to one platform, case-insensitively")
    func platformFilter() async throws {
        stubFeedAndImages()

        try await harness.run(["runtime", "available", "--platform", "watchos"])

        let table = try #require(harness.ui.tables.first)
        #expect(table.rows.map { $0[0] } == ["watchOS"])
    }

    @Test("--json emits the catalog entries with an installed flag")
    func json() async throws {
        stubFeedAndImages()

        try await harness.run(["runtime", "available", "--json", "--prerelease"])

        #expect(harness.ui.tables.isEmpty)
        #expect(harness.ui.outputText.contains("\"build\" : \"23F77\""))
        #expect(harness.ui.outputText.contains("\"installed\" : true"))
        #expect(harness.ui.outputText.contains("\"installed\" : false"))
    }

    @Test("points at runtime install for the next step")
    func installHint() async throws {
        stubFeedAndImages()

        try await harness.run(["runtime", "available"])

        #expect(harness.ui.events.contains { event in
            if case let .info(message) = event { return message.contains("mirage runtime install") }
            return false
        })
    }

    @Test("rejects unknown platforms before touching the network")
    func unknownPlatform() throws {
        #expect(throws: (any Error).self) {
            try Mirage.parseAsRoot(["runtime", "available", "--platform", "android"])
        }
        #expect(harness.runner.executed.isEmpty)
    }

    @Test("surfaces a download failure as a themed error")
    func networkFailure() async throws {
        harness.runner.stub(stderr: "curl: (6) Could not resolve host", exitCode: 6)

        let exit = try await harness.runExpectingExit(["runtime", "available"])

        #expect(exit == ExitCode(1))
        let message = try #require(harness.ui.errorMessages.first)
        #expect(message.contains("Could not resolve host"))
        #expect(message.contains("catalog"))
    }
}
