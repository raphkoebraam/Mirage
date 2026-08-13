import MirageKit
import Synchronization

/// Test double for `CommandRunning`: records every invocation and replays
/// stubbed outputs in FIFO order (last stub is sticky).
public final class MockCommandRunner: CommandRunning, Sendable {
    private struct State {
        var executed: [Command] = []
        var stubs: [CommandOutput] = []
        var interactiveStubs: [Int32] = []
    }

    private let state = Mutex(State())

    public init() {}

    /// Every command passed to `run` or `runInteractive`, in order.
    public var executed: [Command] {
        state.withLock(\.executed)
    }

    public var lastCommand: Command? {
        executed.last
    }

    /// Queues an output. Stubs are consumed FIFO; the final stub is reused
    /// when the queue runs dry so single-stub tests stay terse.
    public func stub(stdout: String = "", stderr: String = "", exitCode: Int32 = 0) {
        state.withLock {
            $0.stubs.append(CommandOutput(standardOutput: stdout, standardError: stderr, exitCode: exitCode))
        }
    }

    public func stubInteractive(exitCode: Int32 = 0) {
        state.withLock { $0.interactiveStubs.append(exitCode) }
    }

    public func run(_ command: Command) throws -> CommandOutput {
        state.withLock {
            $0.executed.append(command)
            guard let first = $0.stubs.first else {
                return CommandOutput(standardOutput: "", standardError: "", exitCode: 0)
            }
            if $0.stubs.count > 1 { $0.stubs.removeFirst() }
            return first
        }
    }

    public func runInteractive(_ command: Command) throws -> Int32 {
        state.withLock {
            $0.executed.append(command)
            guard let first = $0.interactiveStubs.first else { return 0 }
            if $0.interactiveStubs.count > 1 { $0.interactiveStubs.removeFirst() }
            return first
        }
    }
}
