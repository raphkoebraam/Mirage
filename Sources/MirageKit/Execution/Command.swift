import Foundation

/// A fully-resolved invocation of an external executable.
public struct Command: Equatable, Sendable, CustomStringConvertible {
    public let executable: String
    public let arguments: [String]

    public init(executable: String, arguments: [String]) {
        self.executable = executable
        self.arguments = arguments
    }

    public var description: String {
        ([executable] + arguments).joined(separator: " ")
    }
}

/// The captured result of running a `Command` to completion.
public struct CommandOutput: Equatable, Sendable {
    public let standardOutput: String
    public let standardError: String
    public let exitCode: Int32

    public init(standardOutput: String, standardError: String, exitCode: Int32) {
        self.standardOutput = standardOutput
        self.standardError = standardError
        self.exitCode = exitCode
    }
}

/// Thrown by `runChecked` when a command exits with a non-zero status.
public struct CommandFailure: Error, Equatable, Sendable, CustomStringConvertible {
    public let command: Command
    public let exitCode: Int32
    public let standardError: String
    public let standardOutput: String

    public init(command: Command, exitCode: Int32, standardError: String, standardOutput: String) {
        self.command = command
        self.exitCode = exitCode
        self.standardError = standardError
        self.standardOutput = standardOutput
    }

    public var description: String {
        let detail = standardError.isEmpty ? standardOutput : standardError
        let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            ? "`\(command)` exited with code \(exitCode)"
            : trimmed
    }
}

/// The single seam through which mirage touches the operating system.
public protocol CommandRunning: Sendable {
    /// Runs the command to completion, capturing output. Non-zero exits do not throw.
    func run(_ command: Command) throws -> CommandOutput

    /// Runs the command with stdio inherited from the current process
    /// (for streaming/interactive subcommands) and returns its exit code.
    func runInteractive(_ command: Command) throws -> Int32
}

extension CommandRunning {
    /// Runs the command and throws `CommandFailure` on a non-zero exit.
    @discardableResult
    public func runChecked(_ command: Command) throws -> CommandOutput {
        let output = try run(command)
        guard output.exitCode == 0 else {
            throw CommandFailure(
                command: command,
                exitCode: output.exitCode,
                standardError: output.standardError,
                standardOutput: output.standardOutput
            )
        }
        return output
    }
}
