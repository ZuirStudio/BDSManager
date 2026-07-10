import Foundation

struct Server: Codable, Identifiable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var rconPort: Int
    var rconPassword: String
    var residentPlayers: [ResidentPlayer]
    var ops: [OpPlayer]

    init(id: UUID = UUID(), name: String, host: String, port: Int = 19132, rconPort: Int = 19132, rconPassword: String = "", residentPlayers: [ResidentPlayer] = [], ops: [OpPlayer] = []) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.rconPort = rconPort
        self.rconPassword = rconPassword
        self.residentPlayers = residentPlayers
        self.ops = ops
    }

    var displayAddress: String {
        "\(host):\(port)"
    }
}

struct ResidentPlayer: Codable, Identifiable {
    let id: UUID
    var name: String
    var xuid: String
    let addedAt: Date

    init(id: UUID = UUID(), name: String, xuid: String, addedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.xuid = xuid
        self.addedAt = addedAt
    }
}

struct OpPlayer: Codable, Identifiable {
    let id: UUID
    var name: String
    var xuid: String
    var level: Int
    var bypassesPlayerLimit: Bool

    init(id: UUID = UUID(), name: String, xuid: String, level: Int = 4, bypassesPlayerLimit: Bool = true) {
        self.id = id
        self.name = name
        self.xuid = xuid
        self.level = level
        self.bypassesPlayerLimit = bypassesPlayerLimit
    }
}

enum ServerStatus {
    case disconnected
    case connecting
    case connected

    var label: String {
        switch self {
        case .disconnected: return "未连接"
        case .connecting: return "连接中"
        case .connected: return "已连接"
        }
    }
}
