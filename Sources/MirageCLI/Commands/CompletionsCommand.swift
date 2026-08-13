import ArgumentParser

struct CompletionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "completions",
        abstract: "Print a shell completion script.",
        discussion: """
        zsh:  mirage completions zsh > ~/.zsh/completions/_mirage
        bash: mirage completions bash > /usr/local/etc/bash_completion.d/mirage
        fish: mirage completions fish > ~/.config/fish/completions/mirage.fish
        """
    )

    enum Shell: String, ExpressibleByArgument, CaseIterable {
        case zsh, bash, fish

        var completionShell: CompletionShell {
            switch self {
            case .zsh: .zsh
            case .bash: .bash
            case .fish: .fish
            }
        }
    }

    @Argument(help: "The shell: zsh, bash, or fish.")
    var shell: Shell

    func run() async throws {
        CLIRuntime.ui.output(Mirage.completionScript(for: shell.completionShell))
    }
}
