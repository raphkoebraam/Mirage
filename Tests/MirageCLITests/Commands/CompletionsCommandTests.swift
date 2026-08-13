import ArgumentParser
import Testing
@testable import MirageCLI

@Suite("mirage completions")
struct CompletionsCommandTests {
    @Test("emits a zsh completion script")
    func zsh() async throws {
        let harness = CLIHarness()

        try await harness.run(["completions", "zsh"])

        #expect(harness.runner.executed.isEmpty)
        #expect(harness.ui.outputText.contains("#compdef mirage"))
    }

    @Test("emits bash and fish scripts too")
    func otherShells() async throws {
        for shell in ["bash", "fish"] {
            let harness = CLIHarness()
            try await harness.run(["completions", shell])
            #expect(!harness.ui.outputText.isEmpty)
        }
    }

    @Test("rejects unknown shells")
    func unknownShell() async throws {
        let harness = CLIHarness()

        await #expect(throws: (any Error).self) {
            try await harness.run(["completions", "powershell"])
        }
    }
}
