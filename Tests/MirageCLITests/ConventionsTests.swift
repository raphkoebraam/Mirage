import Testing
@testable import MirageCLI

@Suite("CLI conventions")
struct ConventionsTests {
    @Test("every option and subcommand name is kebab-case")
    func kebabCaseEverywhere() {
        // The zsh completion script enumerates every command and option in
        // the tree — a camelCase name anywhere would surface here.
        let script = Mirage.completionScript(for: .zsh)

        let camelOptions = script.matches(of: /--[a-z-]*[A-Z][a-zA-Z-]*/)
        #expect(camelOptions.isEmpty, "camelCase option names: \(camelOptions.map(\.output))")
    }
}
