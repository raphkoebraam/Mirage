/// A watch-phone simulator pair.
public struct DevicePair: Equatable, Sendable {
    /// One side of a pair, as reported inside `pairs` (a reduced device record).
    public struct Member: Equatable, Sendable, Codable {
        public let name: String
        public let udid: String
        public let state: DeviceState

        public init(name: String, udid: String, state: DeviceState) {
            self.name = name
            self.udid = udid
            self.state = state
        }
    }

    public let udid: String
    public let state: String
    public let watch: Member
    public let phone: Member

    public init(udid: String, state: String, watch: Member, phone: Member) {
        self.udid = udid
        self.state = state
        self.watch = watch
        self.phone = phone
    }
}
