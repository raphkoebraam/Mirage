import ArgumentParser
import MirageKit

struct OpenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "open",
        abstract: "Open a URL on a simulator (https, deep links, etc.)."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "The URL to open.")
    var url: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try simctl.openURL(udid: resolved.udid, url: url)
            CLIRuntime.ui.success("Opened \(url) on \(resolved.name).")
        }
    }
}

struct PushCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "push",
        abstract: "Send a simulated push notification.",
        discussion: "Without a payload file the JSON payload is read from stdin. "
            + "The payload may embed 'Simulator Target Bundle' instead of passing a bundle id."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "Target app's bundle identifier.")
    var bundleID: String?

    @Argument(help: "Path to the APNS JSON payload (stdin when omitted).")
    var payload: String?

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try simctl.push(udid: resolved.udid, bundleID: bundleID, payloadPath: payload ?? "-")
            CLIRuntime.ui.success("Push delivered to \(resolved.name).")
        }
    }
}

struct PrivacyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "privacy",
        abstract: "Grant, revoke, or reset privacy permissions.",
        discussion: "Services: all, calendar, contacts, contacts-limited, location, "
            + "location-always, photos, photos-add, media-library, microphone, motion, reminders, siri."
    )

    enum Action: String, ExpressibleByArgument, CaseIterable {
        case grant, revoke, reset
    }

    @Argument(help: "Action: grant, revoke, or reset.")
    var action: Action

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "The privacy service to modify.")
    var service: String

    @Argument(help: "Target app's bundle identifier (required for grant/revoke).")
    var bundleID: String?

    func validate() throws {
        if action != .reset, bundleID == nil {
            throw ValidationError("\(action.rawValue) requires a bundle identifier.")
        }
    }

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            let simctlAction: Simctl.PrivacyAction = switch action {
            case .grant: .grant
            case .revoke: .revoke
            case .reset: .reset
            }
            try simctl.privacy(udid: resolved.udid, action: simctlAction, service: service, bundleID: bundleID)
            CLIRuntime.ui.success("\(action.rawValue) \(service) for \(bundleID ?? "all apps") on \(resolved.name).")
        }
    }
}

struct StatusBarCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "statusbar",
        abstract: "Override or clear status bar values.",
        subcommands: [
            StatusBarOverrideCommand.self,
            StatusBarClearCommand.self,
            StatusBarListCommand.self,
        ]
    )
}

struct StatusBarOverrideCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "override",
        abstract: "Set status bar overrides (at least one flag required)."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Option(name: .long, help: "Fixed time string (ISO dates also set the date).")
    var time: String?

    @Option(name: .long, help: "hide, wifi, 3g, 4g, lte, lte-a, lte+, 5g, 5g+, 5g-uwb, 5g-uc.")
    var dataNetwork: String?

    @Option(name: .long, help: "searching, failed, or active.")
    var wifiMode: String?

    @Option(name: .long, help: "0-3.")
    var wifiBars: Int?

    @Option(name: .long, help: "notSupported, searching, failed, or active.")
    var cellularMode: String?

    @Option(name: .long, help: "0-4.")
    var cellularBars: Int?

    @Option(name: .long, help: "Carrier name.")
    var operatorName: String?

    @Option(name: .long, help: "charging, charged, or discharging.")
    var batteryState: String?

    @Option(name: .long, help: "0-100.")
    var batteryLevel: Int?

    var overrides: StatusBarOverrides {
        var value = StatusBarOverrides()
        value.time = time
        value.dataNetwork = dataNetwork
        value.wifiMode = wifiMode
        value.wifiBars = wifiBars
        value.cellularMode = cellularMode
        value.cellularBars = cellularBars
        value.operatorName = operatorName
        value.batteryState = batteryState
        value.batteryLevel = batteryLevel
        return value
    }

    func validate() throws {
        guard !overrides.isEmpty else {
            throw ValidationError("Provide at least one override flag (e.g. --time '9:41').")
        }
    }

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try simctl.statusBarOverride(udid: resolved.udid, overrides: overrides)
            CLIRuntime.ui.success("Status bar overridden on \(resolved.name).")
        }
    }
}

struct StatusBarClearCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear",
        abstract: "Clear all status bar overrides."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try simctl.statusBarClear(udid: resolved.udid)
            CLIRuntime.ui.success("Status bar overrides cleared on \(resolved.name).")
        }
    }
}

struct StatusBarListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List current status bar overrides."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    func run() async throws {
        try await withErrorPresentation {
            let simctl = CLIRuntime.simctl
            let resolved = try simctl.resolvedDevice(device)
            try CLIRuntime.ui.output(simctl.statusBarList(udid: resolved.udid))
        }
    }
}

struct UICommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ui",
        abstract: "Get or set simulator UI options.",
        subcommands: [
            UIAppearanceCommand.self,
            UIContentSizeCommand.self,
            UIIncreaseContrastCommand.self,
        ]
    )
}

struct UIAppearanceCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "appearance",
        abstract: "Get or set light/dark appearance."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "light or dark (omit to print the current value).")
    var value: String?

    func run() async throws {
        try await runUIOption(option: "appearance", device: device, value: value)
    }
}

struct UIContentSizeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "content-size",
        abstract: "Get or set the preferred content size category."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "A size category, increment, or decrement (omit to print).")
    var value: String?

    func run() async throws {
        try await runUIOption(option: "content_size", device: device, value: value)
    }
}

struct UIIncreaseContrastCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "increase-contrast",
        abstract: "Get or set Increase Contrast mode."
    )

    @Argument(help: "Device (name, UDID, prefix, or 'booted').")
    var device: String

    @Argument(help: "enabled or disabled (omit to print the current value).")
    var value: String?

    func run() async throws {
        try await runUIOption(option: "increase_contrast", device: device, value: value)
    }
}

private func runUIOption(option: String, device: String, value: String?) async throws {
    try await withErrorPresentation {
        let simctl = CLIRuntime.simctl
        let resolved = try simctl.resolvedDevice(device)
        if let value {
            try simctl.setUIOption(udid: resolved.udid, option: option, value: value)
            CLIRuntime.ui.success("Set \(option) to \(value) on \(resolved.name).")
        } else {
            try CLIRuntime.ui.output(simctl.uiOption(udid: resolved.udid, option: option))
        }
    }
}
