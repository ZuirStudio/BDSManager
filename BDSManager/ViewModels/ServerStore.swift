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
    @Published var serverTPS: Double = 0.0
    @Published var serverVersion: String = "未知"
    @Published var serverLevelName: String = "未知"
    @Published var backups: [BackupInfo] = []
    @Published var lastError: String? = nil

    private let rconService = RCONService()
    private let saveKey = "bds_servers"
    private let activeKey = "bds_active_server"

    init() {
        loadServers()
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
        guard let server = activeServer else {
            lastError = "没有选择服务器"
            return
        }

        // 验证必填字段
        guard !server.host.isEmpty else {
            lastError = "服务器地址不能为空"
            connectionStatus = .disconnected
            return
        }

        guard !server.rconPassword.isEmpty else {
            lastError = "RCON 密码不能为空"
            connectionStatus = .disconnected
            return
        }

        lastError = nil
        connectionStatus = .connecting

        do {
            let success = try await rconService.connect(host: server.host, port: server.rconPort, password: server.rconPassword)
            if success {
                connectionStatus = .connected
                consoleMessages.append(ConsoleMessage(content: "已连接到 \(server.name)", type: .info))
            } else {
                connectionStatus = .disconnected
                lastError = "认证失败，请检查 RCON 密码"
                consoleMessages.append(ConsoleMessage(content: "连接失败：RCON 认证失败", type: .error))
            }
        } catch let error as RCONError {
            connectionStatus = .disconnected
            lastError = error.localizedDescription
            consoleMessages.append(ConsoleMessage(content: "连接失败：\(error.localizedDescription)", type: .error))
        } catch {
            connectionStatus = .disconnected
            lastError = error.localizedDescription
            consoleMessages.append(ConsoleMessage(content: "连接失败：\(error.localizedDescription)", type: .error))
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
            consoleMessages.append(ConsoleMessage(content: "未连接到服务器，请先连接", type: .error))
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

    // MARK: - 备份管理
    func deleteBackup(_ backup: BackupInfo) {
        backups.removeAll { $0.id == backup.id }
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
