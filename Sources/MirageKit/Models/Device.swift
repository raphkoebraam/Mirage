import Foundation

/// A simulator device, flattened from `simctl list -j`'s per-runtime grouping.
public struct Device: Equatable, Sendable, Codable {
    public let udid: String
    public let name: String
    public let state: DeviceState
    public let isAvailable: Bool
    public let deviceTypeIdentifier: String?
    public let runtimeIdentifier: String
    public let dataPath: String?
    public let dataPathSize: Int64?
    public let logPath: String?
    public let availabilityError: String?
    public let lastUsedAt: Date?

    public init(
        udid: String,
        name: String,
        state: DeviceState,
        isAvailable: Bool,
        deviceTypeIdentifier: String? = nil,
        runtimeIdentifier: String,
        dataPath: String? = nil,
        dataPathSize: Int64? = nil,
        logPath: String? = nil,
        availabilityError: String? = nil,
        lastUsedAt: Date? = nil
    ) {
        self.udid = udid
        self.name = name
        self.state = state
        self.isAvailable = isAvailable
        self.deviceTypeIdentifier = deviceTypeIdentifier
        self.runtimeIdentifier = runtimeIdentifier
        self.dataPath = dataPath
        self.dataPathSize = dataPathSize
        self.logPath = logPath
        self.availabilityError = availabilityError
        self.lastUsedAt = lastUsedAt
    }

    public var isBooted: Bool {
        state == .booted
    }
}
