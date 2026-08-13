import ArgumentParser
import MirageKit

/// Root command of the `mirage` CLI.
public struct Mirage: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "mirage",
        abstract: "A humane CLI for managing Apple simulators.",
        version: MirageVersion.current,
        subcommands: []
    )

    public init() {}
}

/// Async-safe entry point used by the `mirage` executable's top-level code.
/// Calling `Mirage.main()` directly from `main.swift` resolves to the
/// synchronous `ParsableCommand.main()` overload, which cannot run async
/// subcommands; this wrapper guarantees the async overload is chosen.
public enum MirageMain {
    public static func run() async {
        await Mirage.main()
    }
}
