import ArgumentParser
import MirageKit

/// Root command of the `mirage` CLI.
public struct Mirage: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "mirage",
        abstract: "A humane CLI for managing Apple simulators.",
        version: MirageVersion.current,
        subcommands: [
            ListCommand.self,
            BootedCommand.self,
            CreateCommand.self,
            CloneCommand.self,
            DeleteCommand.self,
            RenameCommand.self,
            BootCommand.self,
            ShutdownCommand.self,
            EraseCommand.self,
            UpgradeCommand.self,
            CleanupCommand.self,
            DuCommand.self,
            AppCommand.self,
            ScreenshotCommand.self,
            RecordCommand.self,
            MediaCommand.self,
            OpenCommand.self,
            PushCommand.self,
            PrivacyCommand.self,
            StatusBarCommand.self,
            UICommand.self,
            GetenvCommand.self,
            ICloudSyncCommand.self,
            LogverboseCommand.self,
            KeychainCommand.self,
            LocationCommand.self,
            PasteboardCommand.self,
            PairCommand.self,
            UnpairCommand.self,
            PairActivateCommand.self,
            SpawnCommand.self,
            DiagnoseCommand.self,
            RuntimeCommand.self,
            LogsCommand.self,
            DoctorCommand.self,
            CompletionsCommand.self,
        ],
        groupedSubcommands: []
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
