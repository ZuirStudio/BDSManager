import Foundation
import SwiftUI

@MainActor
class ServerStore: ObservableObject {
    @Published var servers: [Server] = []
    @Published var activeServerId: UUID? = nil
    @Published var connectionStatus: ServerStatus = .disconnected
    @Published var onlinePlayers: [Player] = []
    @Published var consoleMessages: [ConsoleMessage] = []
    @Published var mods: [ModInfo] = []
    @Published var serverTPS: Double = 20.0
    @Published var serverVersion: String = "1.21.50"
    @Published var serverLevelName: String = "Bedrock Level"
    @Published var backups: [BackupInfo] = []

    private let rconService = RCONService()
    private let saveKey = "bds_servers"
    private let activeKey = "bds_active_server"

    init() {
        loadServers()
        loadMockData()
    }

    // MARK: - 模拟数据（开发用）
    private func loadMockData() {
        if servers.isEmpty {
            let mockServer = Server(
                name: "我的 BDS 服务器",
                host: "192.168.1.100",
                port: 19132,
                rconPort: 19132,
                rconPassword: "password",
                residentPlayers: [
                    ResidentPlayer(name: "Steve", xuid: "2535407668787878"),
                    ResidentPlayer(name: "Alex", xuid: "2535407668787879"),
                ],
                ops: [
                    OpPlayer(name: "Steve", xuid: "2535407668787878", level: 4),
                    OpPlayer(name: "Admin", xuid: "2535407668787880", level: 3),
                ]
            )
            servers = [mockServer]
            activeServerId = mockServer.id
        }

        onlinePlayers = [
            Player(name: "Steve", xuid: "2535407668787878", isOnline: true, ping: 35, gamemode: "survival"),
            Player(name: "Alex", xuid: "2535407668787879", isOnline: true, ping: 48, gamemode: "creative"),
            Player(name: "Notch", xuid: "2535407668787881", isOnline: true, ping: 22, gamemode: "survival"),
        ]

        mods = [
            ModInfo(name: "GeyserMC", version: "2.4.0", enabled: true, description: "允许 Bedrock 玩家加入 Java 服务器", author: "GeyserMC Team"),
            ModInfo(name: "Floodgate", version: "2.2.0", enabled: false, description: "允许 Bedrock 玩家使用 Xbox Live 认证登录", author: "GeyserMC Team"),
            ModInfo(name: "LuckPerms", version: "5.4.100", enabled: true, description: "高级权限管理插件", author: "Luck"),
            ModInfo(name: "WorldEdit", version: "7.2.15", enabled: true, description: "世界编辑工具", author: "EngineHub"),
        ]

        backups = [
            BackupInfo(name: "自动备份", size: "128 MB", date: Date().addingTimeInterval(-86400)),
            BackupInfo(name: "手动备份", size: "112 MB", date: Date().addingTimeInterval(-172800)),
        ]
    }

    // MARK: - 服务器管理
    func addServer(_ server: Server) {
        servers.append(server)
        saveServers()
    }

    func updateServer(_ server: Server) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            saveServers()
        }
    }

    func deleteServer(_ server: Server) {
        servers.removeAll { $0.id == server.id }
        if activeServerId == server.id {
            activeServerId = servers.first?.id
        }
        saveServers()
    }

    func setActiveServer(_ id: UUID) {
        activeServerId = id
        UserDefaults.standard.set(id.uuidString, forKey: activeKey)
    }

    var activeServer: Server? {
        guard let id = activeServerId else { return nil }
        return servers.first { $0.id == id }
    }

    // MARK: - 连接
    func connectToServer() async {
        guard let server = activeServer else { return }
        connectionStatus = .connecting
        do {
            let success = try await rconService.connect(host: server.host, port: server.rconPort, password: server.rconPassword)
            connectionStatus = success ? .connected : .disconnected
        } catch {
            connectionStatus = .disconnected
        }
    }

    func disconnectServer() {
        Task {
            await rconService.disconnect()
        }
        connectionStatus = .disconnected
    }

    // MARK: - 命令
    func executeCommand(_ command: String) async {
        consoleMessages.append(ConsoleMessage(content: "> \(command)", type: .command))

        if connectionStatus == .connected {
            do {
                let response = try await rconService.sendCommand(command)
                consoleMessages.append(ConsoleMessage(content: response, type: .response))
                parseCommandResponse(command: command, response: response)
            } catch {
                consoleMessages.append(ConsoleMessage(content: "错误: \(error.localizedDescription)", type: .error))
            }
        } else {
            // 模拟模式
            let response = mockCommandResponse(command)
            consoleMessages.append(ConsoleMessage(content: response, type: .response))
            parseCommandResponse(command: command, response: response)
        }
    }

    private func mockCommandResponse(_ command: String) -> String {
        let parts = command.split(separator: " ")
        let cmd = String(parts[0]).lowercased()

        switch cmd {
        case "list":
            return "当前在线 \(onlinePlayers.count)/20 名玩家: \(onlinePlayers.map { $0.name }.joined(separator: ", "))"
        case "tps":
            return "TPS: 20.0"
        case "version":
            return "Minecraft Bedrock Dedicated Server v\(serverVersion)"
        case "help":
            return "可用命令: list, tps, version, op, deop, whitelist, kick, say, tell, stop"
        case "op":
            if parts.count > 1 { return "已将 \(parts[1]) 设为管理员" }
            return "用法: op <玩家名>"
        case "deop":
            if parts.count > 1 { return "已移除 \(parts[1]) 的管理员权限" }
            return "用法: deop <玩家名>"
        case "say":
            if parts.count > 1 { return "[服务器] \(parts[1...].joined(separator: " "))" }
            return "用法: say <消息>"
        case "tell":
            if parts.count > 2 { return "已向 \(parts[1]) 发送私聊消息" }
            return "用法: tell <玩家名> <消息>"
        case "whitelist":
            return "白名单: Steve, Alex, Admin"
        case "kick":
            if parts.count > 1 { return "已将 \(parts[1]) 踢出服务器" }
            return "用法: kick <玩家名>"
        case "stop":
            return "正在停止服务器..."
        default:
            return "未知命令: \(cmd)。输入 help 查看可用命令。"
        }
    }

    private func parseCommandResponse(command: String, response: String) {
        let parts = command.split(separator: " ")
        let cmd = String(parts[0]).lowercased()

        switch cmd {
        case "op":
            if parts.count > 1 {
                let name = String(parts[1])
                if let index = servers.firstIndex(where: { $0.id == activeServerId }) {
                    if !servers[index].ops.contains(where: { $0.name == name }) {
                        servers[index].ops.append(OpPlayer(name: name, xuid: ""))
                        saveServers()
                    }
                }
            }
        case "deop":
            if parts.count > 1 {
                let name = String(parts[1])
                if let index = servers.firstIndex(where: { $0.id == activeServerId }) {
                    servers[index].ops.removeAll { $0.name == name }
                    saveServers()
                }
            }
        default:
            break
        }
    }

    // MARK: - 玩家管理
    func kickPlayer(_ player: Player) async {
        await executeCommand("kick \(player.name)")
        onlinePlayers.removeAll { $0.id == player.id }
    }

    func sendMessage(to player: Player, message: String) async {
        await executeCommand("tell \(player.name) \(message)")
    }

    func setOp(_ player: Player, level: Int = 4) async {
        await executeCommand("op \(player.name)")
    }

    func removeOp(_ player: Player) async {
        await executeCommand("deop \(player.name)")
    }

    func setResident(_ player: Player) {
        guard let serverId = activeServerId,
              let serverIndex = servers.firstIndex(where: { $0.id == serverId }) else { return }
        if !servers[serverIndex].residentPlayers.contains(where: { $0.name == player.name }) {
            servers[serverIndex].residentPlayers.append(ResidentPlayer(name: player.name, xuid: player.xuid))
            saveServers()
        }
    }

    func removeResident(_ player: ResidentPlayer) {
        guard let serverId = activeServerId,
              let serverIndex = servers.firstIndex(where: { $0.id == serverId }) else { return }
        servers[serverIndex].residentPlayers.removeAll { $0.id == player.id }
        saveServers()
    }

    // MARK: - Mod 管理
    func toggleMod(_ mod: ModInfo) {
        if let index = mods.firstIndex(where: { $0.id == mod.id }) {
            mods[index].enabled.toggle()
        }
    }

    // MARK: - 持久化
    private func saveServers() {
        if let data = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func loadServers() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Server].self, from: data) {
            servers = decoded
        }
        if let idStr = UserDefaults.standard.string(forKey: activeKey) {
            activeServerId = UUID(uuidString: idStr)
        }
    }
}
