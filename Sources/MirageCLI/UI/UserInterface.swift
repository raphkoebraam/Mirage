/// Presentation seam for the CLI. Command logic talks to this protocol only;
/// Noora lives exclusively behind the `NooraUI` adapter so tests can use a
/// recording fake and non-interactive environments degrade gracefully.
public protocol UserInterface: Sendable {
    func success(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)

    /// Raw data output (paths, JSON, passthrough text) — always plain stdout.
    func output(_ text: String)

    func table(headers: [String], rows: [[String]])

    /// Runs `task` behind a spinner when the terminal supports it.
    func progress(
        _ message: String,
        successMessage: String?,
        task: @escaping @Sendable () async throws -> Void
    ) async throws

    /// Asks a yes/no question. Non-interactive environments return `defaultAnswer`.
    func confirm(_ question: String, defaultAnswer: Bool) -> Bool

    /// Presents a single-choice picker. Returns nil when the environment
    /// cannot prompt (non-TTY), letting callers fail with guidance instead.
    func choose(_ question: String, options: [String]) -> String?

    /// Whether prompts can actually be presented.
    var isInteractive: Bool { get }
}
