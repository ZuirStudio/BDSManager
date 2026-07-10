import Foundation

struct ModInfo: Identifiable {
    let id: String
    var name: String
    var version: String
    var enabled: Bool
    var description: String
    var author: String

    init(id: String = UUID().uuidString, name: String, version: String = "1.0.0", enabled: Bool = true, description: String = "", author: String = "") {
        self.id = id
        self.name = name
        self.version = version
        self.enabled = enabled
        self.description = description
        self.author = author
    }
}

struct ConsoleMessage: Identifiable {
    let id: UUID
    let content: String
    let type: MessageType
    let timestamp: Date

    enum MessageType {
        case command
        case response
        case error
        case info
    }

    init(id: UUID = UUID(), content: String, type: MessageType = .response, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.type = type
        self.timestamp = timestamp
    }
}

struct BackupInfo: Identifiable {
    let id: UUID
    var name: String
    var size: String
    var date: Date

    init(id: UUID = UUID(), name: String, size: String, date: Date = Date()) {
        self.id = id
        self.name = name
        self.size = size
        self.date = date
    }
}
