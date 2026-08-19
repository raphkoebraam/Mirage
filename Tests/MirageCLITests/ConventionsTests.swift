import ArgumentParser
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

@Suite("CLI conventions: positionals")
struct PositionalConventionsTests {
    /// Positional arguments are reserved for the thing a command acts on:
    /// a device (or two, for pairing and pasteboard sync), or, for commands
    /// that have no device, the single subject they target. Every other
    /// value is a named option so invocations read unambiguously.
    static let allowedPositionals: Set<String> = [
        "<device>", "<devices>", "<watch>", "<phone>", "<source>", "<destination>",
        "<pair>", "<shell>", "<identifier>",
        // Pass-through argument lists after "--".
        "<app-arguments>", "<executable-arguments>",
    ]

    @Test("only devices (and command subjects) are positional")
    func onlyDevicesArePositional() {
        var offenders: [String] = []
        for command in allCommands(Mirage.self) {
            // Drop option values ("--type <type>") so only positionals remain.
            let usage = command.usageString()
                .replacing(/--?[a-zA-Z-]+[ =]<[a-z-]+>/, with: "")
                .replacingOccurrences(of: "<subcommand>", with: "")
            let positionals = usage.matches(of: /<[a-z-]+>/).map { String($0.output) }
            for positional in positionals where !Self.allowedPositionals.contains(positional) {
                offenders.append("\(command._commandName): \(positional)")
            }
        }
        #expect(offenders.isEmpty, "unexpected positionals: \(offenders)")
    }

    private func allCommands(_ root: ParsableCommand.Type) -> [ParsableCommand.Type] {
        [root] + root.configuration.subcommands.flatMap { allCommands($0) }
    }
}
