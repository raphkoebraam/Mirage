import ArgumentParser
import MirageKit

/// Runs a command body, converting domain failures into a themed error alert
/// plus a non-zero exit code instead of ArgumentParser's raw error dump.
func withErrorPresentation(_ body: @Sendable () async throws -> Void) async throws {
    do {
        try await body()
    } catch let failure as CommandFailure {
        CLIRuntime.ui.error(failure.description)
        throw ExitCode(failure.exitCode == 0 ? 1 : failure.exitCode)
    } catch let resolution as ResolutionError {
        CLIRuntime.ui.error(resolution.description)
        throw ExitCode(1)
    } catch let mirage as MirageCLIError {
        CLIRuntime.ui.error(mirage.description)
        throw ExitCode(1)
    }
}

/// CLI-level usage errors (bad flag combinations, refused non-interactive
/// prompts, …) with actionable messages.
struct MirageCLIError: Error, CustomStringConvertible, Equatable {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

extension Simctl {
    /// Fetches the inventory and resolves a device query in one step —
    /// the common preamble of almost every command.
    func resolvedDevice(_ query: String) throws -> Device {
        try DeviceResolver(inventory: list()).resolveDevice(query)
    }
}
