import Foundation

/// The complete state of the simulator installation, parsed from
/// `simctl list -j`: device types, runtimes, devices, and pairs.
public struct SimulatorInventory: Equatable, Sendable {
    public let deviceTypes: [DeviceType]
    public let runtimes: [SimRuntime]
    public let devices: [Device]
    public let pairs: [DevicePair]

    public init(
        deviceTypes: [DeviceType],
        runtimes: [SimRuntime],
        devices: [Device],
        pairs: [DevicePair]
    ) {
        self.deviceTypes = deviceTypes
        self.runtimes = runtimes
        self.devices = devices
        self.pairs = pairs
    }

    public var bootedDevices: [Device] {
        devices.filter(\.isBooted)
    }

    public var availableDevices: [Device] {
        devices.filter(\.isAvailable)
    }

    public func runtime(withIdentifier identifier: String) -> SimRuntime? {
        runtimes.first { $0.identifier == identifier }
    }

    public func deviceType(withIdentifier identifier: String) -> DeviceType? {
        deviceTypes.first { $0.identifier == identifier }
    }

    /// All available runtimes matching a query: an exact identifier, a
    /// display name (case-insensitive), or a bare version — the latter can
    /// match several platforms (e.g. "26.0" → iOS 26.0 and watchOS 26.0).
    public func runtimes(matching query: String) -> [SimRuntime] {
        runtimes.filter { runtime in
            runtime.isAvailable && (
                runtime.identifier == query
                    || runtime.name.caseInsensitiveCompare(query) == .orderedSame
                    || runtime.version == query
            )
        }
    }
}

extension SimulatorInventory {
    /// Parses the JSON emitted by `simctl list -j`, flattening the
    /// runtime-keyed device map and the UDID-keyed pair map.
    public init(json: String) throws {
        let payload = try JSONDecoder().decode(Payload.self, from: Data(json.utf8))

        let devices = payload.devices
            .flatMap { runtimeIdentifier, records in
                records.map { record in
                    Device(
                        udid: record.udid,
                        name: record.name,
                        state: record.state,
                        isAvailable: record.isAvailable ?? true,
                        deviceTypeIdentifier: record.deviceTypeIdentifier,
                        runtimeIdentifier: runtimeIdentifier,
                        dataPath: record.dataPath,
                        dataPathSize: record.dataPathSize,
                        logPath: record.logPath,
                        availabilityError: record.availabilityError
                    )
                }
            }
            .sorted { ($0.runtimeIdentifier, $0.name) < ($1.runtimeIdentifier, $1.name) }

        let pairs = payload.pairs
            .map { udid, record in
                DevicePair(udid: udid, state: record.state, watch: record.watch, phone: record.phone)
            }
            .sorted { $0.udid < $1.udid }

        self.init(
            deviceTypes: payload.devicetypes,
            runtimes: payload.runtimes,
            devices: devices,
            pairs: pairs
        )
    }

    private struct Payload: Decodable {
        let devicetypes: [DeviceType]
        let runtimes: [SimRuntime]
        let devices: [String: [DeviceRecord]]
        let pairs: [String: PairRecord]
    }

    private struct DeviceRecord: Decodable {
        let udid: String
        let name: String
        let state: DeviceState
        let isAvailable: Bool?
        let deviceTypeIdentifier: String?
        let dataPath: String?
        let dataPathSize: Int64?
        let logPath: String?
        let availabilityError: String?
    }

    private struct PairRecord: Decodable {
        let state: String
        let watch: DevicePair.Member
        let phone: DevicePair.Member
    }
}
