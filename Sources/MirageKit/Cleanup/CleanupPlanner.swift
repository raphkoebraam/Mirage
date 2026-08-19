import Foundation

/// Computes which simulators are safe to remove, in tiers:
///
/// 1. **unavailable** — their runtime is gone; they can never boot again.
/// 2. **duplicate** — same (name, device type, runtime); one copy is kept
///    (a booted one if any, else the one with the most data).
/// 3. **staleRuntime** (opt-in) — shutdown devices whose runtime is older
///    than the newest available runtime for the same platform.
///
/// Booted devices, devices mid-operation (creating/booting), and members of
/// watch–phone pairs are never selected: deleting half a pair breaks it
/// silently, and busy devices are not safe to remove.
public struct CleanupPlanner: Sendable {
    private let inventory: SimulatorInventory

    public init(inventory: SimulatorInventory) {
        self.inventory = inventory
    }

    /// - Parameters:
    ///   - includeStaleRuntimes: adds shutdown devices on non-latest runtimes.
    ///   - runtimeIdentifiers: runtimes whose shutdown devices should all be
    ///     removed (an explicit user request — the duplicate keep rule does
    ///     not apply, but booted/pair protections still do).
    public func plan(
        includeStaleRuntimes: Bool = false,
        runtimeIdentifiers: Set<String> = []
    ) -> CleanupPlan {
        var entries: [CleanupPlan.Entry] = []
        var selected = Set<String>()

        func select(_ device: Device, _ reason: CleanupPlan.Reason) {
            guard selected.insert(device.udid).inserted else { return }
            entries.append(CleanupPlan.Entry(device: device, reason: reason))
        }

        for device in inventory.devices where !device.isAvailable {
            select(device, .unavailable)
        }

        let pairMemberUDIDs = Set(inventory.pairs.flatMap { [$0.watch.udid, $0.phone.udid] })

        // Only idle, available, non-paired devices are candidates for the
        // remaining tiers.
        let candidates = inventory.availableDevices.filter { device in
            device.state == .shutdown && !pairMemberUDIDs.contains(device.udid)
        }

        for loser in duplicateLosers(among: candidates) {
            select(loser.device, .duplicate(keptUDID: loser.keptUDID))
        }

        if includeStaleRuntimes {
            for (device, newest) in staleDevices(among: candidates) {
                select(device, .staleRuntime(newestRuntime: newest))
            }
        }

        for device in candidates where runtimeIdentifiers.contains(device.runtimeIdentifier) {
            let name = inventory.runtime(withIdentifier: device.runtimeIdentifier)?.name
                ?? device.runtimeIdentifier
            select(device, .requestedRuntime(runtime: name))
        }

        return CleanupPlan(entries: entries.sorted { lhs, rhs in
            if lhs.reason.tier != rhs.reason.tier { return lhs.reason.tier < rhs.reason.tier }
            if lhs.device.name != rhs.device.name { return lhs.device.name < rhs.device.name }
            return lhs.device.udid < rhs.device.udid
        })
    }

    // MARK: - Tiers

    private struct DuplicateLoser {
        let device: Device
        let keptUDID: String
    }

    /// Groups by (name, device type, runtime). The kept copy is a booted
    /// duplicate when one exists (even though booted devices are outside
    /// `candidates`, they still count as the keeper), otherwise the most
    /// recently used one (what Xcode's destination menu prefers and what the
    /// user has been working with), then the one with the most data; ties
    /// keep the lowest UDID for determinism.
    private func duplicateLosers(among candidates: [Device]) -> [DuplicateLoser] {
        struct GroupKey: Hashable {
            let name: String
            let type: String?
            let runtime: String
        }

        let allAvailable = inventory.availableDevices
        let grouped = Dictionary(grouping: allAvailable) { device in
            GroupKey(name: device.name, type: device.deviceTypeIdentifier, runtime: device.runtimeIdentifier)
        }

        let candidateUDIDs = Set(candidates.map(\.udid))

        return grouped.values.flatMap { group -> [DuplicateLoser] in
            guard group.count > 1 else { return [] }

            let kept = group.first(where: \.isBooted)
                ?? group.max { lhs, rhs in
                    let lhsUsed = lhs.lastUsedAt ?? .distantPast
                    let rhsUsed = rhs.lastUsedAt ?? .distantPast
                    if lhsUsed != rhsUsed { return lhsUsed < rhsUsed }
                    let lhsSize = lhs.dataPathSize ?? 0
                    let rhsSize = rhs.dataPathSize ?? 0
                    return lhsSize != rhsSize ? lhsSize < rhsSize : lhs.udid > rhs.udid
                }!

            return group
                .filter { $0.udid != kept.udid && candidateUDIDs.contains($0.udid) }
                .map { DuplicateLoser(device: $0, keptUDID: kept.udid) }
        }
    }

    /// Devices whose runtime version is below the newest available runtime
    /// of the same platform. Returns the newest runtime's display name.
    private func staleDevices(among candidates: [Device]) -> [(Device, String)] {
        let availableRuntimes = inventory.runtimes.filter(\.isAvailable)
        let newestByPlatform: [String: SimRuntime] = availableRuntimes.reduce(into: [:]) { result, runtime in
            guard let platform = runtime.platform else { return }
            if let current = result[platform],
               current.version.compareNumerically(to: runtime.version) != .orderedAscending {
                return
            }
            result[platform] = runtime
        }

        return candidates.compactMap { device in
            guard
                let runtime = inventory.runtime(withIdentifier: device.runtimeIdentifier),
                let platform = runtime.platform,
                let newest = newestByPlatform[platform],
                runtime.version.compareNumerically(to: newest.version) == .orderedAscending
            else { return nil }
            return (device, newest.name)
        }
    }
}

/// The deletion set `mirage cleanup` proposes: what goes, why, and how much
/// disk it reclaims.
public struct CleanupPlan: Equatable, Sendable {
    public enum Reason: Equatable, Sendable, CustomStringConvertible {
        case unavailable
        case duplicate(keptUDID: String)
        case staleRuntime(newestRuntime: String)
        case requestedRuntime(runtime: String)

        public var description: String {
            switch self {
            case .unavailable:
                "unavailable"
            case let .duplicate(keptUDID):
                "duplicate — keeping \(keptUDID.prefix(8))"
            case let .staleRuntime(newestRuntime):
                "stale runtime — newest is \(newestRuntime)"
            case let .requestedRuntime(runtime):
                "on \(runtime) (requested)"
            }
        }

        var tier: Int {
            switch self {
            case .unavailable: 0
            case .duplicate: 1
            case .staleRuntime: 2
            case .requestedRuntime: 3
            }
        }
    }

    public struct Entry: Equatable, Sendable {
        public let device: Device
        public let reason: Reason

        public init(device: Device, reason: Reason) {
            self.device = device
            self.reason = reason
        }
    }

    public let entries: [Entry]

    public init(entries: [Entry]) {
        self.entries = entries
    }

    public var isEmpty: Bool {
        entries.isEmpty
    }

    public var deletedUDIDs: [String] {
        entries.map(\.device.udid)
    }

    public var totalReclaimableBytes: Int64 {
        entries.reduce(0) { $0 + ($1.device.dataPathSize ?? 0) }
    }
}
