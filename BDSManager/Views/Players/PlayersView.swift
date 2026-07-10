import SwiftUI

struct PlayersView: View {
    @EnvironmentObject var store: ServerStore
    @State private var selectedTab = 0
    @State private var selectedPlayer: Player?
    @State private var showPlayerInfo = false
    @State private var showSendMessage = false
    @State private var messageText = ""
    @State private var showActionSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("玩家类型", selection: $selectedTab) {
                    Text("在线").tag(0)
                    Text("常驻").tag(1)
                    Text("管理员").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                Group {
                    switch selectedTab {
                    case 0: onlinePlayersList
                    case 1: residentPlayersList
                    case 2: opsPlayersList
                    default: EmptyView()
                    }
                }
            }
            .navigationTitle("玩家管理")
            .sheet(isPresented: $showPlayerInfo) {
                if let player = selectedPlayer {
                    PlayerInfoSheet(player: player)
                }
            }
            .alert("发送消息", isPresented: $showSendMessage) {
                TextField("消息内容", text: $messageText)
                Button("发送") {
                    if let player = selectedPlayer, !messageText.isEmpty {
                        Task { await store.sendMessage(to: player, message: messageText) }
                        messageText = ""
                    }
                }
                Button("取消", role: .cancel) { messageText = "" }
            } message: {
                Text("发送给 \(selectedPlayer?.name ?? "")")
            }
            .confirmationDialog("玩家操作", isPresented: $showActionSheet) {
                if let player = selectedPlayer {
                    Button("查看信息") { showPlayerInfo = true }
                    Button("发送消息") { showSendMessage = true }
                    Button("设为常驻") { store.setResident(player) }
                    Button("设为管理员") { Task { await store.setOp(player) } }
                    Button("踢出服务器", role: .destructive) { Task { await store.kickPlayer(player) } }
                    Button("取消", role: .cancel) { }
                }
            }
        }
    }

    // MARK: - 在线玩家
    private var onlinePlayersList: some View {
        List {
            if store.onlinePlayers.isEmpty {
                ContentUnavailableView("没有在线玩家", systemImage: "person.2")
            } else {
                ForEach(store.onlinePlayers) { player in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name)
                                .font(.headline)
                            HStack(spacing: 8) {
                                Text(player.gamemodeLabel)
                                Text("·")
                                Text("\(player.ping)ms")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()

                        if store.activeServer?.ops.contains(where: { $0.name == player.name }) == true {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPlayer = player
                        showActionSheet = true
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - 常驻玩家
    private var residentPlayersList: some View {
        List {
            if let server = store.activeServer {
                let onlineResidents = server.residentPlayers.filter { rp in
                    store.onlinePlayers.contains(where: { $0.name == rp.name })
                }
                let offlineResidents = server.residentPlayers.filter { rp in
                    !store.onlinePlayers.contains(where: { $0.name == rp.name })
                }

                if !onlineResidents.isEmpty {
                    Section("在线") {
                        ForEach(onlineResidents) { resident in
                            HStack {
                                Circle().fill(Color.green).frame(width: 10, height: 10)
                                Text(resident.name)
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                                    .opacity(server.ops.contains(where: { $0.name == resident.name }) ? 1 : 0)
                            }
                        }
                    }
                }

                if !offlineResidents.isEmpty {
                    Section("离线") {
                        ForEach(offlineResidents) { resident in
                            HStack {
                                Circle().fill(Color.gray).frame(width: 10, height: 10)
                                Text(resident.name)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("离线")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGroupedBackground))
                                    .clipShape(Capsule())
                            }
                            .contextMenu {
                                Button("设为管理员") { Task { await store.executeCommand("op \(resident.name)") } }
                                Button("取消管理员") { Task { await store.executeCommand("deop \(resident.name)") } }
                                Button("移除常驻", role: .destructive) { store.removeResident(resident) }
                            }
                        }
                    }
                }

                if server.residentPlayers.isEmpty {
                    ContentUnavailableView("没有常驻玩家", systemImage: "person.badge.key")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - 管理员
    private var opsPlayersList: some View {
        List {
            if let server = store.activeServer, !server.ops.isEmpty {
                ForEach(server.ops) { op in
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(op.name)
                                .font(.headline)
                            Text("权限等级: \(op.level)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()

                        if op.bypassesPlayerLimit {
                            Text("绕过人数限制")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .contextMenu {
                        Button("取消OP") { Task { await store.executeCommand("deop \(op.name)") } }
                    }
                }
            } else {
                ContentUnavailableView("没有管理员", systemImage: "crown")
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - 玩家信息弹窗
struct PlayerInfoSheet: View {
    @EnvironmentObject var store: ServerStore
    @Environment(\.dismiss) var dismiss
    let player: Player
    @State private var showConsole = false

    var body: some View {
        NavigationStack {
            List {
                Section("基本信息") {
                    LabeledContent("名称", value: player.name)
                    LabeledContent("XUID", value: player.xuid.isEmpty ? "未知" : player.xuid)
                    LabeledContent("状态", value: player.isOnline ? "在线" : "离线")
                }

                Section("游戏信息") {
                    LabeledContent("游戏模式", value: player.gamemodeLabel)
                    LabeledContent("延迟", value: "\(player.ping)ms")
                    LabeledContent("坐标", value: player.position.display)
                }

                Section("权限") {
                    LabeledContent("管理员", value: store.activeServer?.ops.contains(where: { $0.name == player.name }) == true ? "是" : "否")
                    LabeledContent("常驻玩家", value: store.activeServer?.residentPlayers.contains(where: { $0.name == player.name }) == true ? "是" : "否")
                }

                Section {
                    Button {
                        showConsole = true
                    } label: {
                        Label("查看终端输出", systemImage: "terminal")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("玩家信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showConsole) {
                NavigationStack {
                    ConsoleView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("完成") { showConsole = false }
                            }
                        }
                }
            }
        }
    }
}
