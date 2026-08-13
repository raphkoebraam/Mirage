import Foundation
import MirageKit

/// Test double for `CommandRunning`: records every invocation and replays
/// stubbed outputs in FIFO order (last stub is sticky).
public final class MockCommandRunner: CommandRunning, @unchecked Sendable {
    public struct UnexpectedCommand: Error, CustomStringConvertible {
        public let command: Command
        public var description: String { "No stub for command: \(command)" }
    }

    private let lock = NSLock()
    private var _executed: [Command] = []
    private var stubs: [CommandOutput] = []
    private var interactiveStubs: [Int32] = []

    public init() {}

    /// Every command passed to `run` or `runInteractive`, in order.
    public var executed: [Command] {
        lock.lock()
        defer { lock.unlock() }
        return _executed
    }

    public var lastCommand: Command? { executed.last }

    /// Queues an output. Stubs are consumed FIFO; the final stub is reused
    /// when the queue runs dry so single-stub tests stay terse.
    public func stub(stdout: String = "", stderr: String = "", exitCode: Int32 = 0) {
        lock.lock()
        defer { lock.unlock() }
        stubs.append(CommandOutput(standardOutput: stdout, standardError: stderr, exitCode: exitCode))
    }

    public func stubInteractive(exitCode: Int32 = 0) {
        lock.lock()
        defer { lock.unlock() }
        interactiveStubs.append(exitCode)
    }

    public func run(_ command: Command) throws -> CommandOutput {
        lock.lock()
        defer { lock.unlock() }
        _executed.append(command)
        guard let first = stubs.first else {
            return CommandOutput(standardOutput: "", standardError: "", exitCode: 0)
        }
        if stubs.count > 1 { stubs.removeFirst() }
        return first
    }

    public func runInteractive(_ command: Command) throws -> Int32 {
        lock.lock()
        defer { lock.unlock() }
        _executed.append(command)
        guard let first = interactiveStubs.first else { return 0 }
        if interactiveStubs.count > 1 { interactiveStubs.removeFirst() }
        return first
    }
}
