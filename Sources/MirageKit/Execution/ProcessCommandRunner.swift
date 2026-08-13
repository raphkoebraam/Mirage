import Foundation

/// Runs commands with `Foundation.Process`, reading both output pipes
/// concurrently so large output cannot deadlock the pipe buffers.
public struct ProcessCommandRunner: CommandRunning {
    public init() {}

    public func run(_ command: Command) throws -> CommandOutput {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command.executable)
        process.arguments = command.arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        // Drain stderr on a background thread while this thread drains stdout,
        // otherwise a full 64 KiB pipe buffer would block the child forever.
        let stderrBox = Locked(Data())
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            stderrBox.withValue { $0 = data }
            group.leave()
        }

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        group.wait()

        return CommandOutput(
            standardOutput: String(decoding: stdoutData, as: UTF8.self),
            standardError: String(decoding: stderrBox.withValue { $0 }, as: UTF8.self),
            exitCode: process.terminationStatus
        )
    }

    public func runInteractive(_ command: Command) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command.executable)
        process.arguments = command.arguments
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        // Ignore SIGINT in the parent while the child runs: Ctrl-C must reach
        // the child (e.g. to let `simctl io recordVideo` finalize the file)
        // without killing mirage first.
        let previousHandler = signal(SIGINT, SIG_IGN)
        defer { signal(SIGINT, previousHandler) }

        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
}

/// Minimal mutex-protected box used to move data across threads under Swift 6.
final class Locked<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self.value = value
    }

    func withValue<R>(_ body: (inout Value) -> R) -> R {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }
}
