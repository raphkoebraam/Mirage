/// Curated `simctl list -j` payload matching the Xcode 26.6 schema,
/// including edge cases: an unavailable runtime, an unavailable device,
/// a booted device, an unknown device state, and a watch-phone pair.
public enum SimulatorFixtures {
    public static let listJSON = """
    {
      "devicetypes": [
        {
          "productFamily": "iPhone",
          "bundlePath": "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 17 Pro.simdevicetype",
          "maxRuntimeVersion": 4294967295,
          "maxRuntimeVersionString": "65535.255.255",
          "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
          "modelIdentifier": "iPhone18,1",
          "minRuntimeVersionString": "26.0.0",
          "minRuntimeVersion": 1703936,
          "name": "iPhone 17 Pro"
        },
        {
          "productFamily": "Apple Watch",
          "bundlePath": "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/Apple Watch Series 11 (42mm).simdevicetype",
          "maxRuntimeVersion": 4294967295,
          "maxRuntimeVersionString": "65535.255.255",
          "identifier": "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-11-42mm",
          "modelIdentifier": "Watch7,17",
          "minRuntimeVersionString": "26.0.0",
          "minRuntimeVersion": 1703936,
          "name": "Apple Watch Series 11 (42mm)"
        },
        {
          "productFamily": "iPad",
          "bundlePath": "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPad Pro 13-inch (M4).simdevicetype",
          "maxRuntimeVersion": 4294967295,
          "maxRuntimeVersionString": "65535.255.255",
          "identifier": "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4",
          "modelIdentifier": "iPad16,5",
          "minRuntimeVersionString": "17.5.0",
          "minRuntimeVersion": 1114368,
          "name": "iPad Pro 13-inch (M4)"
        }
      ],
      "runtimes": [
        {
          "isAvailable": true,
          "version": "26.0",
          "isInternal": false,
          "buildversion": "23A339",
          "supportedArchitectures": ["arm64"],
          "supportedDeviceTypes": [
            {
              "bundlePath": "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 17 Pro.simdevicetype",
              "name": "iPhone 17 Pro",
              "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
              "productFamily": "iPhone"
            },
            {
              "bundlePath": "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPad Pro 13-inch (M4).simdevicetype",
              "name": "iPad Pro 13-inch (M4)",
              "identifier": "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4",
              "productFamily": "iPad"
            }
          ],
          "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-0",
          "platform": "iOS",
          "bundlePath": "/Library/Developer/CoreSimulator/Volumes/iOS_23A339/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 26.0.simruntime",
          "runtimeRoot": "/Library/Developer/CoreSimulator/Volumes/iOS_23A339/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 26.0.simruntime/Contents/Resources/RuntimeRoot",
          "name": "iOS 26.0"
        },
        {
          "isAvailable": false,
          "version": "17.0",
          "isInternal": false,
          "buildversion": "21A328",
          "supportedArchitectures": ["x86_64", "arm64"],
          "supportedDeviceTypes": [],
          "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-17-0",
          "platform": "iOS",
          "bundlePath": "/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 17.0.simruntime",
          "runtimeRoot": "/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 17.0.simruntime/Contents/Resources/RuntimeRoot",
          "name": "iOS 17.0"
        },
        {
          "isAvailable": true,
          "version": "18.0",
          "isInternal": false,
          "buildversion": "22A3351",
          "supportedArchitectures": ["arm64"],
          "supportedDeviceTypes": [
            {
              "bundlePath": "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 17 Pro.simdevicetype",
              "name": "iPhone 17 Pro",
              "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
              "productFamily": "iPhone"
            }
          ],
          "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-18-0",
          "platform": "iOS",
          "bundlePath": "/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 18.0.simruntime",
          "runtimeRoot": "/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 18.0.simruntime/Contents/Resources/RuntimeRoot",
          "name": "iOS 18.0"
        },
        {
          "isAvailable": true,
          "version": "18.4",
          "isInternal": false,
          "buildversion": "22E238",
          "supportedArchitectures": ["arm64"],
          "supportedDeviceTypes": [
            {
              "bundlePath": "/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 17 Pro.simdevicetype",
              "name": "iPhone 17 Pro",
              "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
              "productFamily": "iPhone"
            }
          ],
          "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-18-4",
          "platform": "iOS",
          "bundlePath": "/Library/Developer/CoreSimulator/Volumes/iOS_22E238/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 18.4.simruntime",
          "runtimeRoot": "/Library/Developer/CoreSimulator/Volumes/iOS_22E238/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 18.4.simruntime/Contents/Resources/RuntimeRoot",
          "name": "iOS 18.4"
        },
        {
          "isAvailable": true,
          "version": "26.0",
          "isInternal": false,
          "buildversion": "23R339",
          "supportedArchitectures": ["arm64"],
          "supportedDeviceTypes": [],
          "identifier": "com.apple.CoreSimulator.SimRuntime.watchOS-26-0",
          "platform": "watchOS",
          "bundlePath": "/Library/Developer/CoreSimulator/Volumes/watchOS_23R339/Library/Developer/CoreSimulator/Profiles/Runtimes/watchOS 26.0.simruntime",
          "runtimeRoot": "/Library/Developer/CoreSimulator/Volumes/watchOS_23R339/Library/Developer/CoreSimulator/Profiles/Runtimes/watchOS 26.0.simruntime/Contents/Resources/RuntimeRoot",
          "name": "watchOS 26.0"
        }
      ],
      "devices": {
        "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [
          {
            "dataPath": "/Users/tester/Library/Developer/CoreSimulator/Devices/9EC7498F-C644-4431-8CA5-CD1432170998/data",
            "dataPathSize": 18337792,
            "lastUsedAt": "2026-08-16T13:31:09Z",
            "logPath": "/Users/tester/Library/Logs/CoreSimulator/9EC7498F-C644-4431-8CA5-CD1432170998",
            "udid": "9EC7498F-C644-4431-8CA5-CD1432170998",
            "isAvailable": true,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "state": "Booted",
            "name": "iPhone 17 Pro"
          },
          {
            "dataPath": "/Users/tester/Library/Developer/CoreSimulator/Devices/11111111-2222-3333-4444-555555555555/data",
            "dataPathSize": 13312,
            "logPath": "/Users/tester/Library/Logs/CoreSimulator/11111111-2222-3333-4444-555555555555",
            "udid": "11111111-2222-3333-4444-555555555555",
            "isAvailable": true,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4",
            "state": "Shutdown",
            "name": "iPad Pro 13-inch (M4)"
          },
          {
            "dataPath": "/Users/tester/Library/Developer/CoreSimulator/Devices/AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE/data",
            "dataPathSize": 13312,
            "logPath": "/Users/tester/Library/Logs/CoreSimulator/AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
            "udid": "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
            "isAvailable": true,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "state": "Creating",
            "name": "Fresh Device"
          },
          {
            "dataPath": "/Users/tester/Library/Developer/CoreSimulator/Devices/12121212-3434-5656-7878-909090909090/data",
            "dataPathSize": 13312,
            "logPath": "/Users/tester/Library/Logs/CoreSimulator/12121212-3434-5656-7878-909090909090",
            "udid": "12121212-3434-5656-7878-909090909090",
            "isAvailable": true,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "state": "Shutdown",
            "name": "Test Phone"
          },
          {
            "dataPath": "/Users/tester/Library/Developer/CoreSimulator/Devices/D0D0D0D0-AAAA-BBBB-CCCC-DDDDDDDDDDDD/data",
            "dataPathSize": 943718400,
            "logPath": "/Users/tester/Library/Logs/CoreSimulator/D0D0D0D0-AAAA-BBBB-CCCC-DDDDDDDDDDDD",
            "udid": "D0D0D0D0-AAAA-BBBB-CCCC-DDDDDDDDDDDD",
            "isAvailable": true,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "state": "Shutdown",
            "name": "iPhone 17 Pro"
          },
          {
            "dataPath": "/Users/tester/Library/Developer/CoreSimulator/Devices/CACACACA-1111-2222-3333-444444444444/data",
            "dataPathSize": 524288000,
            "logPath": "/Users/tester/Library/Logs/CoreSimulator/CACACACA-1111-2222-3333-444444444444",
            "udid": "CACACACA-1111-2222-3333-444444444444",
            "isAvailable": true,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "state": "Shutdown",
            "name": "CI Runner"
          },
          {
            "dataPath": "/Users/tester/Library/Developer/CoreSimulator/Devices/CBCBCBCB-5555-6666-7777-888888888888/data",
            "dataPathSize": 104857600,
            "logPath": "/Users/tester/Library/Logs/CoreSimulator/CBCBCBCB-5555-6666-7777-888888888888",
            "udid": "CBCBCBCB-5555-6666-7777-888888888888",
            "isAvailable": true,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "state": "Shutdown",
            "name": "CI Runner"
          }
        ],
        "com.apple.CoreSimulator.SimRuntime.iOS-18-4": [
          {
            "dataPath": "/Users/tester/Library/Developer/CoreSimulator/Devices/DEDEDEDE-FAFA-1212-3434-565656565656/data",
            "dataPathSize": 13312,
            "logPath": "/Users/tester/Library/Logs/CoreSimulator/DEDEDEDE-FAFA-1212-3434-565656565656",
            "udid": "DEDEDEDE-FAFA-1212-3434-565656565656",
            "isAvailable": true,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "state": "Shutdown",
            "name": "Test Phone"
          }
        ],
        "com.apple.CoreSimulator.SimRuntime.iOS-17-0": [
          {
            "availabilityError": "runtime profile not found using \\"System\\" match policy",
            "dataPath": "/Users/tester/Library/Developer/CoreSimulator/Devices/66666666-7777-8888-9999-000000000000/data",
            "dataPathSize": 0,
            "logPath": "/Users/tester/Library/Logs/CoreSimulator/66666666-7777-8888-9999-000000000000",
            "udid": "66666666-7777-8888-9999-000000000000",
            "isAvailable": false,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
            "state": "Shutdown",
            "name": "Old iPhone"
          }
        ],
        "com.apple.CoreSimulator.SimRuntime.watchOS-26-0": [
          {
            "dataPath": "/Users/tester/Library/Developer/CoreSimulator/Devices/0B1E4D7C-A521-4AD7-B6BC-41B22D122118/data",
            "dataPathSize": 13312,
            "logPath": "/Users/tester/Library/Logs/CoreSimulator/0B1E4D7C-A521-4AD7-B6BC-41B22D122118",
            "udid": "0B1E4D7C-A521-4AD7-B6BC-41B22D122118",
            "isAvailable": true,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-11-42mm",
            "state": "Shutdown",
            "name": "Apple Watch Series 11 (42mm)"
          }
        ]
      },
      "pairs": {
        "E03C944C-146D-4895-AF08-E9D241390C5B": {
          "watch": {
            "name": "Apple Watch Series 11 (42mm)",
            "udid": "0B1E4D7C-A521-4AD7-B6BC-41B22D122118",
            "state": "Shutdown"
          },
          "phone": {
            "name": "iPhone 17 Pro",
            "udid": "9EC7498F-C644-4431-8CA5-CD1432170998",
            "state": "Booted"
          },
          "state": "(active, disconnected)"
        }
      }
    }
    """
}

import Foundation

public extension SimulatorFixtures {
    /// The same inventory with every device shut down, for paths that
    /// need nothing booted.
    static var allShutdownJSON: String {
        listJSON.replacingOccurrences(of: "\"Booted\"", with: "\"Shutdown\"")
    }
}
