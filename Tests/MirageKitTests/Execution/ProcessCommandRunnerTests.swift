import Foundation
import MirageKit
import Testing

@Suite("ProcessCommandRunner")
struct ProcessCommandRunnerTests {
    let runner = ProcessCommandRunner()

    @Test("captures standard output and reports exit code 0")
    func capturesStandardOutput() throws {
        let output = try runner.run(Command(executable: "/bin/echo", arguments: ["hello", "world"]))

        #expect(output.standardOutput == "hello world\n")
        #expect(output.standardError.isEmpty)
        #expect(output.exitCode == 0)
    }

    @Test("captures standard error separately from standard output")
    func capturesStandardError() throws {
        let output = try runner.run(
            Command(executable: "/bin/sh", arguments: ["-c", "echo out; echo err 1>&2"])
        )

        #expect(output.standardOutput == "out\n")
        #expect(output.standardError == "err\n")
    }

    @Test("reports non-zero exit codes without throwing")
    func reportsNonZeroExit() throws {
        let output = try runner.run(Command(executable: "/bin/sh", arguments: ["-c", "exit 3"]))

        #expect(output.exitCode == 3)
    }

    @Test("throws when the executable does not exist")
    func throwsForMissingExecutable() {
        #expect(throws: (any Error).self) {
            try runner.run(Command(executable: "/nonexistent/binary", arguments: []))
        }
    }

    @Test("does not deadlock on output larger than the pipe buffer")
    func handlesLargeOutput() throws {
        // 256 KiB on both streams, well past the 64 KiB pipe buffer.
        let output = try runner.run(
            Command(
                executable: "/bin/sh",
                arguments: ["-c", "yes x | head -c 262144; yes e | head -c 262144 1>&2"]
            )
        )

        #expect(output.standardOutput.count == 262_144)
        #expect(output.standardError.count == 262_144)
    }

    @Test("runChecked throws CommandFailure with stderr for non-zero exits")
    func runCheckedThrows() {
        let command = Command(executable: "/bin/sh", arguments: ["-c", "echo boom 1>&2; exit 9"])

        #expect {
            try runner.runChecked(command)
        } throws: { error in
            guard let failure = error as? CommandFailure else { return false }
            return failure.exitCode == 9
                && failure.standardError == "boom\n"
                && failure.command == command
        }
    }
}

@Suite("Command")
struct CommandTests {
    @Test("renders a shell-like description for diagnostics")
    func description() {
        let command = Command(executable: "/usr/bin/xcrun", arguments: ["simctl", "boot", "ABC"])

        #expect(command.description == "/usr/bin/xcrun simctl boot ABC")
    }
}
