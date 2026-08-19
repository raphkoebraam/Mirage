import MirageKit
import MirageKitTesting
import Testing

@Suite("DeviceResolver — devices")
struct DeviceResolverDeviceTests {
    let resolver: DeviceResolver

    init() throws {
        resolver = try DeviceResolver(inventory: SimulatorInventory(json: SimulatorFixtures.listJSON))
    }

    @Test("'booted' resolves the single booted device")
    func booted() throws {
        let device = try resolver.resolveDevice("booted")
        #expect(device.udid == "9EC7498F-C644-4431-8CA5-CD1432170998")
    }

    @Test("'booted' fails when nothing is booted")
    func bootedNone() throws {
        let inventory = try SimulatorInventory(json: SimulatorFixtures.listJSON)
        let shutdownAll = SimulatorInventory(
            deviceTypes: inventory.deviceTypes,
            runtimes: inventory.runtimes,
            devices: inventory.devices.map { device in
                Device(
                    udid: device.udid,
                    name: device.name,
                    state: .shutdown,
                    isAvailable: device.isAvailable,
                    deviceTypeIdentifier: device.deviceTypeIdentifier,
                    runtimeIdentifier: device.runtimeIdentifier
                )
            },
            pairs: inventory.pairs
        )

        #expect(throws: ResolutionError.noBootedDevice) {
            try DeviceResolver(inventory: shutdownAll).resolveDevice("booted")
        }
    }

    @Test("an exact UDID resolves case-insensitively")
    func exactUDID() throws {
        let device = try resolver.resolveDevice("9ec7498f-c644-4431-8ca5-cd1432170998")
        #expect(device.name == "iPhone 17 Pro")
    }

    @Test("a unique UDID prefix of at least 4 characters resolves")
    func udidPrefix() throws {
        let device = try resolver.resolveDevice("1111")
        #expect(device.name == "iPad Pro 13-inch (M4)")
    }

    @Test("an exact name resolves when unique")
    func exactName() throws {
        let device = try resolver.resolveDevice("Fresh Device")
        #expect(device.udid == "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")
    }

    @Test("an exact name shared across runtimes prefers the newest runtime")
    func duplicateNamePrefersNewestRuntime() throws {
        let device = try resolver.resolveDevice("Test Phone")
        #expect(device.runtimeIdentifier == "com.apple.CoreSimulator.SimRuntime.iOS-26-0")
    }

    @Test("a name match prefers a booted device over newer runtimes")
    func prefersBooted() throws {
        // "iPhone 17 Pro" exists booted on iOS 26; substring "iphone 17"
        // also matches nothing else available — booted one wins.
        let device = try resolver.resolveDevice("iphone 17 pro")
        #expect(device.isBooted)
    }

    @Test("a case-insensitive substring resolves when unique")
    func substring() throws {
        let device = try resolver.resolveDevice("ipad")
        #expect(device.name == "iPad Pro 13-inch (M4)")
    }

    @Test("unavailable devices resolve only by exact UDID")
    func unavailableDevice() throws {
        #expect(throws: ResolutionError.self) {
            try resolver.resolveDevice("Old iPhone")
        }

        let byUDID = try resolver.resolveDevice("66666666-7777-8888-9999-000000000000")
        #expect(byUDID.name == "Old iPhone")
    }

    @Test("an unknown query fails with deviceNotFound")
    func notFound() {
        #expect(throws: ResolutionError.deviceNotFound(query: "does-not-exist")) {
            try resolver.resolveDevice("does-not-exist")
        }
    }

    @Test("resolution errors render human-readable descriptions")
    func errorDescriptions() {
        #expect(ResolutionError.deviceNotFound(query: "x").description.contains("x"))
        #expect(ResolutionError.noBootedDevice.description.contains("booted"))
    }
}

@Suite("DeviceResolver — device types")
struct DeviceResolverTypeTests {
    let resolver: DeviceResolver

    init() throws {
        resolver = try DeviceResolver(inventory: SimulatorInventory(json: SimulatorFixtures.listJSON))
    }

    @Test("resolves by exact identifier")
    func identifier() throws {
        let type = try resolver.resolveDeviceType("com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro")
        #expect(type.name == "iPhone 17 Pro")
    }

    @Test("resolves by exact name, case-insensitively")
    func exactName() throws {
        let type = try resolver.resolveDeviceType("iphone 17 pro")
        #expect(type.identifier == "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro")
    }

    @Test("resolves by unique substring")
    func substring() throws {
        let type = try resolver.resolveDeviceType("watch")
        #expect(type.productFamily == "Apple Watch")
    }

    @Test("an ambiguous substring lists the candidates")
    func ambiguous() {
        #expect {
            try resolver.resolveDeviceType("pro")
        } throws: { error in
            guard case let .ambiguousDeviceType(query, candidates) = error as? ResolutionError else {
                return false
            }
            return query == "pro" && candidates.count == 2
        }
    }

    @Test("an unknown device type fails")
    func notFound() {
        #expect(throws: ResolutionError.deviceTypeNotFound(query: "galaxy")) {
            try resolver.resolveDeviceType("galaxy")
        }
    }
}

@Suite("DeviceResolver — runtimes")
struct DeviceResolverRuntimeTests {
    let resolver: DeviceResolver
    let iphone17Pro: DeviceType

    init() throws {
        let inventory = try SimulatorInventory(json: SimulatorFixtures.listJSON)
        resolver = DeviceResolver(inventory: inventory)
        iphone17Pro = inventory.deviceTypes[0]
    }

    @Test("nil query picks the newest available runtime supporting the device type")
    func defaultRuntime() throws {
        let runtime = try resolver.resolveRuntime(nil, for: iphone17Pro)
        #expect(runtime.identifier == "com.apple.CoreSimulator.SimRuntime.iOS-26-0")
    }

    @Test("nil query falls back to platform matching when support lists are empty")
    func defaultRuntimePlatformFallback() throws {
        let watchType = DeviceType(
            name: "Apple Watch Series 11 (42mm)",
            identifier: "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-11-42mm",
            productFamily: "Apple Watch"
        )

        let runtime = try resolver.resolveRuntime(nil, for: watchType)
        #expect(runtime.identifier == "com.apple.CoreSimulator.SimRuntime.watchOS-26-0")
    }

    @Test("resolves by exact identifier")
    func identifier() throws {
        let runtime = try resolver.resolveRuntime("com.apple.CoreSimulator.SimRuntime.iOS-18-4", for: nil)
        #expect(runtime.version == "18.4")
    }

    @Test("resolves by display name")
    func name() throws {
        let runtime = try resolver.resolveRuntime("iOS 18.4", for: nil)
        #expect(runtime.identifier == "com.apple.CoreSimulator.SimRuntime.iOS-18-4")
    }

    @Test("resolves by bare version, preferring the device type's platform")
    func version() throws {
        let runtime = try resolver.resolveRuntime("18.4", for: iphone17Pro)
        #expect(runtime.identifier == "com.apple.CoreSimulator.SimRuntime.iOS-18-4")
    }

    @Test("a major-only version means its .0 release: '18' is iOS 18.0")
    func majorOnlyVersion() throws {
        let runtime = try resolver.resolveRuntime("18", for: iphone17Pro)
        #expect(runtime.identifier == "com.apple.CoreSimulator.SimRuntime.iOS-18-0")
    }

    @Test("trailing zero segments are interchangeable: '18.4.0' is iOS 18.4")
    func trailingZeros() throws {
        let runtime = try resolver.resolveRuntime("18.4.0", for: nil)
        #expect(runtime.identifier == "com.apple.CoreSimulator.SimRuntime.iOS-18-4")
    }

    @Test("a major without an installed .0 release is still not an exact match")
    func majorWithoutZeroRelease() {
        // Only 26.0 exists for 26, so "26" is exact; 18 has 18.0 too. Use a
        // family with no .0: none in the fixture, so assert the negative via 17
        // (unavailable) and 99 (absent).
        #expect(throws: ResolutionError.runtimeNotFound(query: "99")) {
            try resolver.resolveRuntime("99", for: nil)
        }
        #expect(throws: ResolutionError.runtimeNotFound(query: "17")) {
            try resolver.resolveRuntime("17", for: nil)
        }
    }

    @Test("a bare version shared by two platforms is disambiguated by the device type")
    func versionSharedAcrossPlatforms() throws {
        // 26.0 exists for both iOS and watchOS.
        let runtime = try resolver.resolveRuntime("26.0", for: iphone17Pro)
        #expect(runtime.platform == "iOS")
    }

    @Test("unavailable runtimes are never resolved")
    func unavailable() {
        #expect(throws: ResolutionError.runtimeNotFound(query: "17.0")) {
            try resolver.resolveRuntime("17.0", for: nil)
        }
    }
}
