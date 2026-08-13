/// Lifecycle state of a simulator device, as spelled by `simctl`.
/// Unknown spellings are preserved rather than dropped so new Xcode
/// releases cannot break parsing.
public enum DeviceState: Equatable, Hashable, Sendable {
    case booted
    case shutdown
    case booting
    case shuttingDown
    case creating
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "Booted": self = .booted
        case "Shutdown": self = .shutdown
        case "Booting": self = .booting
        case "Shutting Down": self = .shuttingDown
        case "Creating": self = .creating
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .booted: "Booted"
        case .shutdown: "Shutdown"
        case .booting: "Booting"
        case .shuttingDown: "Shutting Down"
        case .creating: "Creating"
        case let .unknown(value): value
        }
    }
}

extension DeviceState: Codable {
    public init(from decoder: any Decoder) throws {
        try self.init(rawValue: decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
