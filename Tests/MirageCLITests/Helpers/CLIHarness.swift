import ArgumentParser
import MirageKit
import MirageKitTesting
@testable import MirageCLI

/// End-to-end harness: parses argv exactly like the shipped binary and runs
/// the command against a mock runner and recording UI. No simulator, no TTY.
struct CLIHarness {
    let runner = MockCommandRunner()
    let ui: RecordingUI

    init(isInteractive: Bool = true) {
        ui = RecordingUI(isInteractive: isInteractive)
    }

    /// Stubs the `simctl list -j` call that most commands issue first.
    func stubInventory(_ json: String = SimulatorFixtures.listJSON) {
        runner.stub(stdout: json)
    }

    @discardableResult
    func run(_ arguments: [String]) async throws -> [Command] {
        var command = try Mirage.parseAsRoot(arguments)
        try await CLIRuntime.$runner.withValue(runner) {
            try await CLIRuntime.$ui.withValue(ui) {
                if var asyncCommand = command as? any AsyncParsableCommand {
                    try await asyncCommand.run()
                } else {
                    try command.run()
                }
            }
        }
        return runner.executed
    }

    /// Runs and expects a clean-exit failure (`ExitCode`), returning it.
    func runExpectingExit(_ arguments: [String]) async throws -> ExitCode? {
        do {
            try await run(arguments)
            return nil
        } catch let exit as ExitCode {
            return exit
        }
    }

    /// The commands executed after the initial `list -j` preamble.
    var commandsAfterList: [Command] {
        runner.executed.filter { $0.arguments != ["simctl", "list", "-j"] }
    }

    var lastArguments: [String]? {
        runner.lastCommand.map { Array($0.arguments.dropFirst()) } // drop "simctl"
    }
}
