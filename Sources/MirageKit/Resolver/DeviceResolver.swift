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

    private static func platform(forProductFamily family: String) -> String {
        switch family {
        case "iPhone", "iPad": "iOS"
        case "Apple Watch": "watchOS"
        case "Apple TV": "tvOS"
        case "Apple Vision": "xrOS"
        default: family
        }
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
