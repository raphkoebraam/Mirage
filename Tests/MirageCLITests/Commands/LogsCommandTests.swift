import ArgumentParser
import Testing
@testable import MirageCLI

@Suite("mirage logs")
struct LogsCommandTests {
    let harness = CLIHarness()

    @Test("streams the unified log via spawn")
    func basic() async throws {
        harness.stubInventory()
        harness.runner.stubInteractive(exitCode: 0)

        try await harness.run(["logs", "booted"])

        #expect(harness.lastArguments == [
            "spawn", "9EC7498F-C644-4431-8CA5-CD1432170998", "log", "stream",
        ])
    }

    @Test("forwards predicate and level")
    func predicateAndLevel() async throws {
        harness.stubInventory()
        harness.runner.stubInteractive(exitCode: 0)

        try await harness.run([
            "logs", "booted",
            "--predicate", #"subsystem == "com.example""#,
            "--level", "debug",
        ])

        #expect(harness.lastArguments == [
            "spawn", "9EC7498F-C644-4431-8CA5-CD1432170998", "log", "stream",
            "--predicate", #"subsystem == "com.example""#,
            "--level", "debug",
        ])
    }

    @Test("--app builds a process predicate")
    func appShortcut() async throws {
        harness.stubInventory()
        harness.runner.stubInteractive(exitCode: 0)

        try await harness.run(["logs", "booted", "--app", "MyApp"])

        #expect(harness.lastArguments == [
            "spawn", "9EC7498F-C644-4431-8CA5-CD1432170998", "log", "stream",
            "--predicate", #"process == "MyApp""#,
        ])
    }
}
