import Foundation
import MirageKit

/// Task-local dependency injection for commands. Production uses the real
/// process runner and Noora UI; tests override both with
/// `CLIRuntime.$runner.withValue(...)` / `CLIRuntime.$ui.withValue(...)`.
public enum CLIRuntime {
    @TaskLocal public static var runner: any CommandRunning = ProcessCommandRunner()
    @TaskLocal public static var ui: any UserInterface = NooraUI()

    /// Custom CoreSimulator device set. Defaults to the MIRAGE_DEVICE_SET
    /// environment variable so CI jobs can isolate their simulators without
    /// threading a flag through every command.
    @TaskLocal public static var deviceSet: String? =
        ProcessInfo.processInfo.environment["MIRAGE_DEVICE_SET"]

    public static var simctl: Simctl {
        Simctl(runner: runner, deviceSet: deviceSet)
    }
}
