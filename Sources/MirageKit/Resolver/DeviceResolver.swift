import Foundation

/// Resolves human-friendly queries — names, UDIDs, UDID prefixes, substrings,
/// the magic string "booted" — against a `SimulatorInventory`.
///
/// Resolution order for devices:
/// 1. `booted` → the single booted device
/// 2. exact UDID (case-insensitive)
/// 3. exact name → falling back to case-insensitive
/// 4. UDID prefix (≥ 4 characters)
/// 5. case-insensitive name substring
///
/// Unavailable devices only resolve via exact UDID. When several devices
/// match by name, a booted one wins, then the newest runtime; remaining ties
/// are reported as ambiguous rather than guessed.
public struct DeviceResolver: Sendable {
    private let inventory: SimulatorInventory

    public init(inventory: SimulatorInventory) {
        self.inventory = inventory
    }

    // MARK: - Devices

    public func resolveDevice(_ query: String) throws -> Device {
        if query.lowercased() == "booted" {
            let booted = inventory.bootedDevices
            switch booted.count {
            case 0: throw ResolutionError.noBootedDevice
            case 1: return booted[0]
            default: throw ResolutionError.ambiguousDevice(query: query, candidates: booted)
            }
        }

        if let device = inventory.devices.first(where: { $0.udid.caseInsensitiveEquals(query) }) {
            return device
        }

        let candidates = inventory.availableDevices

        let exactName = candidates.filter { $0.name == query }
        if let device = try disambiguate(exactName, query: query) {
            return device
        }

        let caseInsensitiveName = candidates.filter { $0.name.caseInsensitiveEquals(query) }
        if let device = try disambiguate(caseInsensitiveName, query: query) {
            return device
        }

        if query.count >= 4 {
            let byPrefix = candidates.filter { $0.udid.lowercased().hasPrefix(query.lowercased()) }
            if let device = try disambiguate(byPrefix, query: query) {
                return device
            }
        }

        let bySubstring = candidates.filter { $0.name.localizedCaseInsensitiveContains(query) }
        if let device = try disambiguate(bySubstring, query: query) {
            return device
        }

        throw ResolutionError.deviceNotFound(query: query)
    }

    /// Applies the preference rules to a set of matches: a single match wins;
    /// among several, a unique booted device wins, then the newest runtime.
    private func disambiguate(_ matches: [Device], query: String) throws -> Device? {
        switch matches.count {
        case 0:
            return nil
        case 1:
            return matches[0]
        default:
            let booted = matches.filter(\.isBooted)
            if booted.count == 1 {
                return booted[0]
            }

            let ranked = matches.sorted { lhs, rhs in
                runtimeVersion(of: lhs).compareNumerically(to: runtimeVersion(of: rhs)) == .orderedDescending
            }
            let bestVersion = runtimeVersion(of: ranked[0])
            let best = ranked.filter { runtimeVersion(of: $0) == bestVersion }
            if best.count == 1 {
                return best[0]
            }
            throw ResolutionError.ambiguousDevice(query: query, candidates: matches)
        }
    }

    private func runtimeVersion(of device: Device) -> String {
        inventory.runtime(withIdentifier: device.runtimeIdentifier)?.version ?? "0"
    }

    // MARK: - Device types

    public func resolveDeviceType(_ query: String) throws -> DeviceType {
        let types = inventory.deviceTypes

        if let type = types.first(where: { $0.identifier == query }) {
            return type
        }
        if let type = types.first(where: { $0.name.caseInsensitiveEquals(query) }) {
            return type
        }

        let bySubstring = types.filter { $0.name.localizedCaseInsensitiveContains(query) }
        switch bySubstring.count {
        case 0: throw ResolutionError.deviceTypeNotFound(query: query)
        case 1: return bySubstring[0]
        default: throw ResolutionError.ambiguousDeviceType(query: query, candidates: bySubstring)
        }
    }

    // MARK: - Runtimes

    /// Resolves a runtime query (identifier, display name, or bare version).
    /// A nil query picks the newest available runtime for `deviceType` —
    /// first via the runtime's supported-device-type list, then by platform.
    public func resolveRuntime(_ query: String?, for deviceType: DeviceType?) throws -> SimRuntime {
        let available = inventory.runtimes
            .filter(\.isAvailable)
            .sorted { $0.version.compareNumerically(to: $1.version) == .orderedDescending }

        guard let query else {
            return try defaultRuntime(for: deviceType, among: available)
        }

        if let runtime = available.first(where: { $0.identifier == query }) {
            return runtime
        }
        if let runtime = available.first(where: { $0.name.caseInsensitiveEquals(query) }) {
            return runtime
        }

        let byVersion = available.filter { $0.version == query }
        switch byVersion.count {
        case 0:
            throw ResolutionError.runtimeNotFound(query: query)
        case 1:
            return byVersion[0]
        default:
            if let deviceType {
                let platform = Self.platform(forProductFamily: deviceType.productFamily)
                if let match = byVersion.first(where: { $0.platform == platform }) {
                    return match
                }
            }
            return byVersion[0]
        }
    }

    /// The newest available runtime for a device type: preferring runtimes
    /// that list the type as supported, falling back to platform matching.
    private func defaultRuntime(for deviceType: DeviceType?, among available: [SimRuntime]) throws -> SimRuntime {
        guard let deviceType else {
            throw ResolutionError.runtimeNotFound(query: nil)
        }
        if let supporting = available.first(where: { runtime in
            runtime.supportedDeviceTypes?.contains { $0.identifier == deviceType.identifier } == true
        }) {
            return supporting
        }
        let platform = Self.platform(forProductFamily: deviceType.productFamily)
        if let byPlatform = available.first(where: { $0.platform == platform }) {
            return byPlatform
        }
        throw ResolutionError.runtimeNotFound(query: nil)
    }

    /// Close-but-not-exact runtime candidates for a query that
    /// `resolveRuntime` rejected: version-family matches ("18" → every
    /// available 18.x) and name fragments ("watch" → watchOS …). Sorted with
    /// the device type's platform first, then newest version.
    public func suggestRuntimes(_ query: String, for deviceType: DeviceType?) -> [SimRuntime] {
        // A numeric query is a version search only — "1" must not match
        // "iOS 18.4" by substring.
        let isVersionQuery = query.split(separator: ".").allSatisfy { Int($0) != nil }
        let matches = inventory.runtimes.filter { runtime in
            guard runtime.isAvailable else { return false }
            return isVersionQuery
                ? Self.versionFamilyMatches(query: query, version: runtime.version)
                : runtime.name.localizedCaseInsensitiveContains(query)
        }

        let preferredPlatform = deviceType.map { Self.platform(forProductFamily: $0.productFamily) }
        return matches.sorted { lhs, rhs in
            if let preferredPlatform {
                let lhsPreferred = lhs.platform == preferredPlatform
                let rhsPreferred = rhs.platform == preferredPlatform
                if lhsPreferred != rhsPreferred { return lhsPreferred }
            }
            switch SemanticVersion.compare(lhs.version, rhs.version) {
            case .orderedDescending: return true
            case .orderedAscending: return false
            case .orderedSame: return lhs.identifier < rhs.identifier
            }
        }
    }

    /// "18" matches 18.x; "18.4" matches 18.4.y; "1" matches nothing —
    /// whole leading segments only.
    private static func versionFamilyMatches(query: String, version: String) -> Bool {
        let querySegments = query.split(separator: ".").map { Int($0) }
        let versionSegments = version.split(separator: ".").map { Int($0) }
        guard !querySegments.isEmpty,
              querySegments.count <= versionSegments.count,
              querySegments.allSatisfy({ $0 != nil }) else {
            return false
        }
        return zip(querySegments, versionSegments).allSatisfy { $0 == $1 }
    }

    private static func platform(forProductFamily family: String) -> String {
        PlatformMapping.platform(forProductFamily: family)
    }
}

/// Failures produced while resolving user queries into concrete simulator
/// entities. Ambiguity is an error by design: mirage never guesses between
/// equally-good candidates.
public enum ResolutionError: Error, Equatable, CustomStringConvertible {
    case noBootedDevice
    case multipleBootedDevices([Device])
    case deviceNotFound(query: String)
    case ambiguousDevice(query: String, candidates: [Device])
    case deviceTypeNotFound(query: String)
    case ambiguousDeviceType(query: String, candidates: [DeviceType])
    case runtimeNotFound(query: String?)

    public var description: String {
        switch self {
        case .noBootedDevice:
            return "No simulator is currently booted."
        case let .multipleBootedDevices(devices):
            return "Multiple simulators are booted: \(devices.map(\.name).joined(separator: ", ")). "
                + "Specify one by name or UDID."
        case let .deviceNotFound(query):
            return "No simulator matches '\(query)'. Run `mirage list` to see available devices."
        case let .ambiguousDevice(query, candidates):
            let names = candidates.map { "\($0.name) [\($0.udid)]" }.joined(separator: "\n  ")
            return "'\(query)' matches multiple simulators:\n  \(names)\nUse a UDID to disambiguate."
        case let .deviceTypeNotFound(query):
            return "No device type matches '\(query)'. Run `mirage list devicetypes` to see options."
        case let .ambiguousDeviceType(query, candidates):
            let names = candidates.map(\.name).joined(separator: ", ")
            return "'\(query)' matches multiple device types: \(names). Be more specific."
        case let .runtimeNotFound(query):
            if let query {
                return "No available runtime matches '\(query)'. Run `mirage list runtimes` to see options."
            }
            return "No available runtime found for that device type."
        }
    }
}

extension String {
    fileprivate func caseInsensitiveEquals(_ other: String) -> Bool {
        caseInsensitiveCompare(other) == .orderedSame
    }

    /// Numeric-aware comparison so "26.0" sorts above "18.4".
    func compareNumerically(to other: String) -> ComparisonResult {
        compare(other, options: .numeric)
    }
}
