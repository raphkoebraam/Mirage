import ArgumentParser
import Foundation
import MirageKit

struct ScreenshotCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screenshot",
        abstract: "Save a screenshot of a simulator."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Option(name: [.short, .long], help: "Output file. Defaults to <device>-<timestamp>.png in the current directory.")
    var output: String?

    @Option(name: .long, help: "Image format: png, tiff, bmp, gif, jpeg.")
    var type: String?

    @Option(name: .long, help: "Display to capture (see `simctl io enumerate`).")
    var display: String?

    @Option(name: .long, help: "Mask policy for non-rectangular displays: ignored, alpha, black.")
    var mask: String?

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            let path = output ?? defaultMediaPath(deviceName: resolved.name, fileExtension: type ?? "png")

            try simctl.screenshot(
                udid: resolved.udid,
                outputPath: path,
                type: type,
                display: display,
                mask: mask
            )

            CLIRuntime.ui.success("Saved screenshot of \(resolved.name).")
            CLIRuntime.ui.output(path)
        }
    }
}

struct RecordCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "record",
        abstract: "Record a video of a simulator (Ctrl-C to stop and finalize)."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Option(name: [.short, .long], help: "Output file. Defaults to <device>-<timestamp>.mov in the current directory.")
    var output: String?

    @Option(name: .long, help: "Codec: h264 or hevc (default).")
    var codec: String?

    @Option(name: .long, help: "Display to record (see `simctl io enumerate`).")
    var display: String?

    @Option(name: .long, help: "Mask policy for non-rectangular displays: ignored, alpha, black.")
    var mask: String?

    @Flag(name: .long, help: "Overwrite the output file if it exists.")
    var force = false

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let ui = CLIRuntime.ui
            let resolved = try simctl.resolvedDevice(device)
            let path = output ?? defaultMediaPath(deviceName: resolved.name, fileExtension: "mov")

            ui.info("Recording \(resolved.name) — press Ctrl-C to stop.")
            let code = try simctl.recordVideo(
                udid: resolved.udid,
                outputPath: path,
                codec: codec,
                display: display,
                mask: mask,
                force: force
            )

            if code == 0 || code == SIGINT {
                ui.success("Saved recording of \(resolved.name).")
                ui.output(path)
            } else {
                throw MirageCLIError("Recording failed (exit code \(code)).")
            }
        }
    }
}

struct MediaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "media",
        abstract: "Add media to a simulator's library.",
        subcommands: [MediaAddCommand.self]
    )
}

struct MediaAddCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add photos, live photos, videos, or contacts."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "Files to add.")
    var paths: [String]

    func validate() throws {
        guard !paths.isEmpty else {
            throw ValidationError("Provide at least one file.")
        }
    }

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try simctl.addMedia(udid: resolved.udid, paths: paths)
            CLIRuntime.ui.success("Added \(paths.count) item(s) to \(resolved.name).")
        }
    }
}

/// `iPhone 17 Pro` → `iPhone-17-Pro-20260813-221530.png`
func defaultMediaPath(deviceName: String, fileExtension: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    let safeName = deviceName
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { !$0.isEmpty }
        .joined(separator: "-")
    return "\(safeName)-\(formatter.string(from: Date())).\(fileExtension)"
}
