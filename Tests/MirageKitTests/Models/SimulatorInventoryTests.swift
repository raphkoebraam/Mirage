import Foundation
import MirageKit
import Testing

@Suite("SimulatorInventory parsing")
struct SimulatorInventoryTests {
    let inventory: SimulatorInventory

    init() throws {
        inventory = try SimulatorInventory(json: SimctlListFixture.json)
    }

    @Test("decodes all device types with their identity fields")
    func deviceTypes() {
        #expect(inventory.deviceTypes.count == 3)

        let iphone = inventory.deviceTypes[0]
        #expect(iphone.name == "iPhone 17 Pro")
        #expect(iphone.identifier == "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro")
        #expect(iphone.productFamily == "iPhone")
        #expect(iphone.modelIdentifier == "iPhone18,1")
    }

    @Test("decodes runtimes including unavailable ones")
    func runtimes() {
        #expect(inventory.runtimes.count == 4)

        let ios26 = inventory.runtimes[0]
        #expect(ios26.identifier == "com.apple.CoreSimulator.SimRuntime.iOS-26-0")
        #expect(ios26.name == "iOS 26.0")
        #expect(ios26.version == "26.0")
        #expect(ios26.buildversion == "23A339")
        #expect(ios26.platform == "iOS")
        #expect(ios26.isAvailable)

        let ios17 = inventory.runtimes[1]
        #expect(!ios17.isAvailable)
    }

    @Test("decodes the device types each runtime supports")
    func runtimeSupportedDeviceTypes() {
        let ios26 = inventory.runtimes[0]
        #expect(
            ios26.supportedDeviceTypes?
                .contains { $0.identifier == "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro" } == true
        )
    }

    @Test("flattens devices and attaches their runtime identifier")
    func devicesAreFlattened() {
        #expect(inventory.devices.count == 7)

        let booted = inventory.devices.first { $0.udid == "9EC7498F-C644-4431-8CA5-CD1432170998" }
        #expect(booted?.runtimeIdentifier == "com.apple.CoreSimulator.SimRuntime.iOS-26-0")
        #expect(booted?.name == "iPhone 17 Pro")
        #expect(booted?.state == .booted)
        #expect(booted?.isAvailable == true)
    }

    @Test("maps known states and preserves unknown ones")
    func deviceStates() {
        let creating = inventory.devices.first { $0.name == "Fresh Device" }
        #expect(creating?.state == .creating)

        let shutdown = inventory.devices.first { $0.name == "Old iPhone" }
        #expect(shutdown?.state == .shutdown)
    }

    @Test("surfaces availability errors on unavailable devices")
    func unavailableDevice() {
        let old = inventory.devices.first { $0.name == "Old iPhone" }
        #expect(old?.isAvailable == false)
        #expect(old?.availabilityError?.contains("runtime profile not found") == true)
    }

    @Test("decodes pairs keyed by their UDID")
    func pairs() {
        #expect(inventory.pairs.count == 1)

        let pair = inventory.pairs[0]
        #expect(pair.udid == "E03C944C-146D-4895-AF08-E9D241390C5B")
        #expect(pair.state == "(active, disconnected)")
        #expect(pair.watch.name == "Apple Watch Series 11 (42mm)")
        #expect(pair.phone.udid == "9EC7498F-C644-4431-8CA5-CD1432170998")
    }

    @Test("bootedDevices returns only booted devices")
    func bootedDevices() {
        #expect(inventory.bootedDevices.map(\.udid) == ["9EC7498F-C644-4431-8CA5-CD1432170998"])
    }

    @Test("availableDevices excludes unavailable ones")
    func availableDevices() {
        #expect(inventory.availableDevices.count == 6)
        #expect(!inventory.availableDevices.contains { $0.name == "Old iPhone" })
    }

    @Test("runtime lookup by identifier")
    func runtimeLookup() {
        let runtime = inventory.runtime(withIdentifier: "com.apple.CoreSimulator.SimRuntime.watchOS-26-0")
        #expect(runtime?.name == "watchOS 26.0")
    }

    @Test("rejects malformed JSON with a descriptive error")
    func malformedJSON() {
        #expect(throws: (any Error).self) {
            _ = try SimulatorInventory(json: "not json at all")
        }
    }

    @Test("device state raw values follow simctl spelling")
    func stateRawValues() {
        #expect(DeviceState(rawValue: "Booted") == .booted)
        #expect(DeviceState(rawValue: "Shutdown") == .shutdown)
        #expect(DeviceState(rawValue: "Booting") == .booting)
        #expect(DeviceState(rawValue: "Shutting Down") == .shuttingDown)
        #expect(DeviceState(rawValue: "Creating") == .creating)
        #expect(DeviceState(rawValue: "Weird Future State") == .unknown("Weird Future State"))
    }
}
