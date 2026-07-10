import Foundation

struct Player: Identifiable {
    let id: String
    var name: String
    var xuid: String
    var isOnline: Bool
    var ping: Int
    var gamemode: String
    var position: Position

    init(id: String = UUID().uuidString, name: String, xuid: String = "", isOnline: Bool = true, ping: Int = 0, gamemode: String = "survival", position: Position = Position()) {
        self.id = id
        self.name = name
        self.xuid = xuid
        self.isOnline = isOnline
        self.ping = ping
        self.gamemode = gamemode
        self.position = position
    }

    var gamemodeLabel: String {
        switch gamemode {
        case "survival": return "生存模式"
        case "creative": return "创造模式"
        case "adventure": return "冒险模式"
        case "spectator": return "旁观模式"
        default: return gamemode
        }
    }
}

struct Position: Codable {
    var x: Double
    var y: Double
    var z: Double

    init(x: Double = 0, y: Double = 0, z: Double = 0) {
        self.x = x
        self.y = y
        self.z = z
    }

    var display: String {
        String(format: "%.1f, %.1f, %.1f", x, y, z)
    }
}
