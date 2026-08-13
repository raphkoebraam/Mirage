import MirageKit

/// Task-local dependency injection for commands. Production uses the real
/// process runner and Noora UI; tests override both with
/// `CLIRuntime.$runner.withValue(...)` / `CLIRuntime.$ui.withValue(...)`.
public enum CLIRuntime {
    @TaskLocal public static var runner: any CommandRunning = ProcessCommandRunner()
    @TaskLocal public static var ui: any UserInterface = NooraUI()

    public static var simctl: Simctl {
        Simctl(runner: runner)
    }
}
