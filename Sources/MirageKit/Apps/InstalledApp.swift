import Foundation

/// An app installed on a simulator, parsed from `simctl listapps` output
/// (an openStep-style plist).
public struct InstalledApp: Equatable, Sendable, Codable {
    public let bundleID: String
    public let displayName: String?
    public let applicationType: String?
    public let version: String?
    public let path: String?

    public init(
        bundleID: String,
        displayName: String? = nil,
        applicationType: String? = nil,
        version: String? = nil,
        path: String? = nil
    ) {
        self.bundleID = bundleID
        self.displayName = displayName
        self.applicationType = applicationType
        self.version = version
        self.path = path
    }

    /// Parses `simctl listapps` output. User apps sort before System apps,
    /// then alphabetically by display name / bundle id.
    public static func parse(listappsOutput: String) throws -> [InstalledApp] {
        let plist = try PropertyListSerialization.propertyList(
            from: Data(listappsOutput.utf8),
            format: nil
        )
        guard let entries = plist as? [String: [String: Any]] else {
            throw ParsingError()
        }

        return entries
            .map { bundleID, info in
                InstalledApp(
                    bundleID: bundleID,
                    displayName: info["CFBundleDisplayName"] as? String
                        ?? info["CFBundleName"] as? String,
                    applicationType: info["ApplicationType"] as? String,
                    version: info["CFBundleVersion"] as? String,
                    path: info["Path"] as? String
                )
            }
            .sorted { lhs, rhs in
                let lhsUser = lhs.applicationType == "User"
                let rhsUser = rhs.applicationType == "User"
                if lhsUser != rhsUser { return lhsUser }
                return (lhs.displayName ?? lhs.bundleID) < (rhs.displayName ?? rhs.bundleID)
            }
    }

    public struct ParsingError: Error, CustomStringConvertible {
        public var description: String { "Could not parse the app list simctl returned." }
    }
}
