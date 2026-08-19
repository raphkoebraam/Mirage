import Foundation

/// An installed runtime disk image, as reported by `simctl runtime list -j`.
public struct RuntimeImage: Equatable, Sendable, Codable {
    public let identifier: String
    public let build: String
    public let version: String
    public let runtimeIdentifier: String?
    public let platformIdentifier: String?
    public let state: String
    public let sizeBytes: Int64?

    public init(
        identifier: String,
        build: String,
        version: String,
        runtimeIdentifier: String? = nil,
        platformIdentifier: String? = nil,
        state: String,
        sizeBytes: Int64? = nil
    ) {
        self.identifier = identifier
        self.build = build
        self.version = version
        self.runtimeIdentifier = runtimeIdentifier
        self.platformIdentifier = platformIdentifier
        self.state = state
        self.sizeBytes = sizeBytes
    }

    /// Parses the `simctl runtime list -j` payload (a dictionary keyed by
    /// image identifier).
    public static func parse(json: String) throws -> [RuntimeImage] {
        let decoded = try JSONDecoder().decode([String: RuntimeImage].self, from: Data(json.utf8))
        return decoded.values.sorted { $0.identifier < $1.identifier }
    }
}
