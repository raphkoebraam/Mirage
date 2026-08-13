/// An installed simulator runtime (e.g. "iOS 26.0").
public struct SimRuntime: Equatable, Sendable, Codable {
    public let identifier: String
    public let name: String
    public let version: String
    public let buildversion: String
    public let platform: String?
    public let isAvailable: Bool
    public let supportedDeviceTypes: [DeviceType]?

    public init(
        identifier: String,
        name: String,
        version: String,
        buildversion: String,
        platform: String? = nil,
        isAvailable: Bool,
        supportedDeviceTypes: [DeviceType]? = nil
    ) {
        self.identifier = identifier
        self.name = name
        self.version = version
        self.buildversion = buildversion
        self.platform = platform
        self.isAvailable = isAvailable
        self.supportedDeviceTypes = supportedDeviceTypes
    }
}
