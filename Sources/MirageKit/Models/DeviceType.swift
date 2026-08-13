/// A simulator device type profile (e.g. "iPhone 17 Pro").
public struct DeviceType: Equatable, Sendable, Codable {
    public let name: String
    public let identifier: String
    public let productFamily: String
    public let modelIdentifier: String?
    public let minRuntimeVersionString: String?
    public let maxRuntimeVersionString: String?

    public init(
        name: String,
        identifier: String,
        productFamily: String,
        modelIdentifier: String? = nil,
        minRuntimeVersionString: String? = nil,
        maxRuntimeVersionString: String? = nil
    ) {
        self.name = name
        self.identifier = identifier
        self.productFamily = productFamily
        self.modelIdentifier = modelIdentifier
        self.minRuntimeVersionString = minRuntimeVersionString
        self.maxRuntimeVersionString = maxRuntimeVersionString
    }
}
