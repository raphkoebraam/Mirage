import MirageKit

/// Resolves a runtime query, and when nothing matches exactly, offers the
/// closest available runtime: interactively as a "did you mean" confirmation,
/// non-interactively as an error that names it.
func resolveRuntimeForgivingly(
    _ query: String?,
    for deviceType: DeviceType?,
    resolver: DeviceResolver,
    ui: any UserInterface,
    assumeYes: Bool = false
) throws -> SimRuntime {
    do {
        return try resolver.resolveRuntime(query, for: deviceType)
    } catch let error as ResolutionError {
        guard case .runtimeNotFound = error,
              let query,
              let closest = resolver.suggestRuntimes(query, for: deviceType).first else {
            throw error
        }

        if assumeYes {
            ui.info("No runtime matches '\(query)' — using the closest, \(closest.name).")
            return closest
        }

        guard ui.isInteractive else {
            throw MirageCLIError(
                "No runtime matches '\(query)'. Closest available: \(closest.name) — "
                    + "re-run with --runtime \"\(closest.version)\"."
            )
        }

        guard ui.confirm(
            "No runtime matches '\(query)'. Use \(closest.name) instead?",
            defaultAnswer: true
        ) else {
            throw MirageCLIError("Aborted.")
        }
        return closest
    }
}

/// Fails with actionable guidance when a device type can't run on a runtime —
/// instead of simctl's bare "Incompatible device" (error 403).
func requireCompatible(
    _ deviceType: DeviceType,
    with runtime: SimRuntime,
    in inventory: SimulatorInventory
) throws {
    guard !inventory.isCompatible(deviceType, with: runtime) else { return }

    var lines = ["\(deviceType.name) isn't compatible with \(runtime.name)."]
    let supporting = uniqued(inventory.runtimes(supporting: deviceType).map(\.name))
    if !supporting.isEmpty {
        lines.append("Runtimes that support it: \(capped(supporting)).")
    }
    let supportedTypes = uniqued(inventory.deviceTypes(supportedBy: runtime).map(\.name))
    if !supportedTypes.isEmpty {
        lines.append("Device types \(runtime.name) supports: \(capped(supportedTypes)).")
    }
    throw MirageCLIError(lines.joined(separator: "\n"))
}

/// Order-preserving dedupe — some machines carry two runtime records for the
/// same version (different builds), which would read as a stutter.
private func uniqued(_ items: [String]) -> [String] {
    var seen = Set<String>()
    return items.filter { seen.insert($0).inserted }
}

private func capped(_ items: [String], limit: Int = 8) -> String {
    items.count <= limit
        ? items.joined(separator: ", ")
        : items.prefix(limit).joined(separator: ", ") + ", … (\(items.count - limit) more)"
}
