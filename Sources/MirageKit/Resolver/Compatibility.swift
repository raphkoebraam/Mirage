import Foundation

/// Segment-aware version comparison: "26.0" == "26.0.0", "18.4" < "26.0".
/// Foundation's `.numeric` string compare treats missing segments as smaller,
/// which would wrongly reject "26.0" against a "26.0.0" minimum.
enum SemanticVersion {
    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let rhsParts = rhs.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0 ..< max(lhsParts.count, rhsParts.count) {
            let left = index < lhsParts.count ? lhsParts[index] : 0
            let right = index < rhsParts.count ? rhsParts[index] : 0
            if left != right {
                return left < right ? .orderedAscending : .orderedDescending
            }
        }
        return .orderedSame
    }
}

/// Maps simctl product families to runtime platforms.
enum PlatformMapping {
    static func platform(forProductFamily family: String) -> String {
        switch family {
        case "iPhone", "iPad": "iOS"
        case "Apple Watch": "watchOS"
        case "Apple TV": "tvOS"
        case "Apple Vision": "xrOS"
        default: family
        }
    }
}

extension SimulatorInventory {
    /// Whether a device type can run on a runtime. The runtime's
    /// supported-device-type list is authoritative when present; otherwise
    /// the platform must match and the device type's min/max runtime version
    /// range decides.
    public func isCompatible(_ deviceType: DeviceType, with runtime: SimRuntime) -> Bool {
        if let supported = runtime.supportedDeviceTypes, !supported.isEmpty {
            return supported.contains { $0.identifier == deviceType.identifier }
        }
        guard runtime.platform == PlatformMapping.platform(forProductFamily: deviceType.productFamily) else {
            return false
        }
        if let minimum = deviceType.minRuntimeVersionString,
           SemanticVersion.compare(runtime.version, minimum) == .orderedAscending {
            return false
        }
        if let maximum = deviceType.maxRuntimeVersionString,
           SemanticVersion.compare(runtime.version, maximum) == .orderedDescending {
            return false
        }
        return true
    }

    /// Available runtimes that can run the device type, newest first.
    public func runtimes(supporting deviceType: DeviceType) -> [SimRuntime] {
        runtimes
            .filter { $0.isAvailable && isCompatible(deviceType, with: $0) }
            .sorted { SemanticVersion.compare($0.version, $1.version) == .orderedDescending }
    }

    /// Device types a runtime can run, resolved against the inventory's full
    /// device-type records.
    public func deviceTypes(supportedBy runtime: SimRuntime) -> [DeviceType] {
        if let supported = runtime.supportedDeviceTypes, !supported.isEmpty {
            return supported.compactMap { deviceType(withIdentifier: $0.identifier) }
        }
        return deviceTypes.filter { isCompatible($0, with: runtime) }
    }
}
