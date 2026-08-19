/// Read-only disk accounting over the inventory. Deletes nothing.
public struct DiskUsage: Equatable, Sendable {
    public struct RuntimeUsage: Equatable, Sendable, Codable {
        public let runtimeIdentifier: String
        public let runtimeName: String
        public let deviceCount: Int
        public let totalBytes: Int64
    }

    public let perRuntime: [RuntimeUsage]
    public let totalBytes: Int64

    private let devicesBySize: [Device]

    public init(inventory: SimulatorInventory) {
        let grouped = Dictionary(grouping: inventory.devices, by: \.runtimeIdentifier)

        perRuntime = grouped
            .map { identifier, devices in
                RuntimeUsage(
                    runtimeIdentifier: identifier,
                    runtimeName: inventory.runtime(withIdentifier: identifier)?.name
                        ?? identifier.replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: ""),
                    deviceCount: devices.count,
                    totalBytes: devices.reduce(0) { $0 + ($1.dataPathSize ?? 0) }
                )
            }
            .sorted { lhs, rhs in
                lhs.totalBytes != rhs.totalBytes
                    ? lhs.totalBytes > rhs.totalBytes
                    : lhs.runtimeName < rhs.runtimeName
            }

        totalBytes = perRuntime.reduce(0) { $0 + $1.totalBytes }

        devicesBySize = inventory.devices.sorted { lhs, rhs in
            let lhsSize = lhs.dataPathSize ?? 0
            let rhsSize = rhs.dataPathSize ?? 0
            return lhsSize != rhsSize ? lhsSize > rhsSize : lhs.udid < rhs.udid
        }
    }

    public func topDevices(_ count: Int) -> [Device] {
        Array(devicesBySize.prefix(count))
    }
}
