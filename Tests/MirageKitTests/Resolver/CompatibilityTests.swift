import MirageKit
import MirageKitTesting
import Testing

@Suite("Runtime suggestions")
struct RuntimeSuggestionTests {
    let resolver: DeviceResolver
    let inventory: SimulatorInventory

    init() throws {
        inventory = try SimulatorInventory(json: SimulatorFixtures.listJSON)
        resolver = DeviceResolver(inventory: inventory)
    }

    @Test("a bare major version suggests its family, closest to the query first")
    func majorVersion() {
        let suggestions = resolver.suggestRuntimes("18", for: nil)

        // "18" means 18.0 — the nearest version wins, not the newest.
        #expect(suggestions.map(\.name) == ["iOS 18.0", "iOS 18.4"])
    }

    @Test("a minor version pulls its nearest neighbors first")
    func minorVersion() {
        let suggestions = resolver.suggestRuntimes("18.3", for: nil)

        #expect(suggestions.first?.name == "iOS 18.4")
    }

    @Test("suggestions are filtered to runtimes the device type can run")
    func compatibilityFilter() {
        let iphone = inventory.deviceTypes[0]

        let suggestions = resolver.suggestRuntimes("18", for: iphone)

        #expect(suggestions.map(\.name) == ["iOS 18.0", "iOS 18.4"])
    }

    @Test("an incompatible family redirects to the closest compatible runtime")
    func incompatibleFamilyRedirects() {
        let ipad = inventory.deviceTypes[2]

        // 18.x exists but none of it supports the iPad in this fixture —
        // the suggestion should be what actually works.
        let suggestions = resolver.suggestRuntimes("18", for: ipad)

        #expect(suggestions.map(\.name) == ["iOS 26.0"])
    }

    @Test("suggestions never include unavailable runtimes")
    func excludesUnavailable() {
        #expect(resolver.suggestRuntimes("17", for: nil).isEmpty)
    }

    @Test("a partial major is not a match — '1' does not mean 17 or 18")
    func noSloppyPrefixes() {
        #expect(resolver.suggestRuntimes("1", for: nil).isEmpty)
    }

    @Test("ambiguous majors resolve to the device type's own platform")
    func platformPreference() {
        let iphone = inventory.deviceTypes[0]

        // "26" exists on iOS and watchOS; only the runtime the iPhone can
        // actually run is suggested.
        let suggestions = resolver.suggestRuntimes("26", for: iphone)

        #expect(suggestions.map(\.identifier) == ["com.apple.CoreSimulator.SimRuntime.iOS-26-0"])
    }

    @Test("name fragments suggest too")
    func nameFragment() {
        let suggestions = resolver.suggestRuntimes("watch", for: nil)

        #expect(suggestions.map(\.platform) == ["watchOS"])
    }

    @Test("nonsense yields no suggestions")
    func nonsense() {
        #expect(resolver.suggestRuntimes("99", for: nil).isEmpty)
    }
}

@Suite("Runtime–device compatibility")
struct CompatibilityTests {
    let inventory: SimulatorInventory
    var iphone17Pro: DeviceType {
        inventory.deviceTypes[0]
    }

    var watchType: DeviceType {
        inventory.deviceTypes[1]
    }

    var ipadType: DeviceType {
        inventory.deviceTypes[2]
    }

    var ios26: SimRuntime {
        inventory.runtimes[0]
    }

    var ios184: SimRuntime {
        inventory.runtime(withIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-18-4")!
    }

    var watchos26: SimRuntime {
        inventory.runtime(withIdentifier: "com.apple.CoreSimulator.SimRuntime.watchOS-26-0")!
    }

    init() throws {
        inventory = try SimulatorInventory(json: SimulatorFixtures.listJSON)
    }

    @Test("the supported-device-type list is authoritative when present")
    func supportedListRules() {
        #expect(inventory.isCompatible(iphone17Pro, with: ios184))
        #expect(inventory.isCompatible(ipadType, with: ios26))
        // iOS 18.4's list has no iPad entry.
        #expect(!inventory.isCompatible(ipadType, with: ios184))
    }

    @Test("an empty list falls back to the min/max runtime version range")
    func versionRangeFallback() {
        // watchOS 26.0 lists no device types; the watch's minimum runtime is
        // 26.0.0, which "26.0" satisfies (segment-aware compare, not string).
        #expect(inventory.isCompatible(watchType, with: watchos26))
        // The iPhone 17 Pro's minimum is 26.0.0 — a fabricated empty-list
        // 18.4 runtime must be rejected by the range check.
        let bareRuntime = SimRuntime(
            identifier: "x",
            name: "iOS 18.4",
            version: "18.4",
            buildversion: "b",
            platform: "iOS",
            isAvailable: true
        )
        #expect(!inventory.isCompatible(iphone17Pro, with: bareRuntime))
    }

    @Test("runtimes(supporting:) lists newest-first compatible runtimes")
    func supportingRuntimes() {
        #expect(inventory.runtimes(supporting: ipadType).map(\.name) == ["iOS 26.0"])
        #expect(inventory.runtimes(supporting: iphone17Pro).map(\.name) == ["iOS 26.0", "iOS 18.4", "iOS 18.0"])
    }

    @Test("deviceTypes(supportedBy:) lists what a runtime can run")
    func supportedDeviceTypes() {
        #expect(inventory.deviceTypes(supportedBy: ios184).map(\.name) == ["iPhone 17 Pro"])
    }
}
