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
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
            .background {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.2),
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.15, green: 0.15, blue: 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - 在线玩家
    private var onlinePlayersList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if store.onlinePlayers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("没有在线玩家")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(store.onlinePlayers) { player in
                        Button {
                            selectedPlayer = player
                            showActionSheet = true
                        } label: {
                            GlassPlayerRow(player: player, isOp: store.activeServer?.ops.contains(where: { $0.name == player.name }) == true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }

    // MARK: - 常驻玩家
    private var residentPlayersList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if let server = store.activeServer {
                    let onlineResidents = server.residentPlayers.filter { rp in
                        store.onlinePlayers.contains(where: { $0.name == rp.name })
                    }
                    let offlineResidents = server.residentPlayers.filter { rp in
                        !store.onlinePlayers.contains(where: { $0.name == rp.name })
                    }

                    if !onlineResidents.isEmpty {
                        sectionHeader(title: "在线")
                        ForEach(onlineResidents) { resident in
                            GlassResidentRow(resident: resident, isOp: server.ops.contains(where: { $0.name == resident.name }), isOnline: true)
                                .contextMenu {
                                    Button("设为管理员") { Task { await store.executeCommand("op \(resident.name)") } }
                                    Button("取消管理员") { Task { await store.executeCommand("deop \(resident.name)") } }
                                    Button("移除常驻", role: .destructive) { store.removeResident(resident) }
                                }
                        }
                    }

                    if !offlineResidents.isEmpty {
                        sectionHeader(title: "离线")
                        ForEach(offlineResidents) { resident in
                            GlassResidentRow(resident: resident, isOp: server.ops.contains(where: { $0.name == resident.name }), isOnline: false)
                                .contextMenu {
                                    Button("设为管理员") { Task { await store.executeCommand("op \(resident.name)") } }
                                    Button("取消管理员") { Task { await store.executeCommand("deop \(resident.name)") } }
                                    Button("移除常驻", role: .destructive) { store.removeResident(resident) }
                                }
                        }
                    }

                    if server.residentPlayers.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.badge.key")
                                .font(.system(size: 50))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("没有常驻玩家")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }

    // MARK: - 管理员
    private var opsPlayersList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if let server = store.activeServer, !server.ops.isEmpty {
                    ForEach(server.ops) { op in
                        GlassOpRow(op: op)
                            .contextMenu {
                                Button("取消OP") { Task { await store.executeCommand("deop \(op.name)") } }
                            }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "crown")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("没有管理员")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
        .padding(.top, 4)
    }
}

struct GlassPlayerRow: View {
    let player: Player
    let isOp: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .shadow(color: .green, radius: 3)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    if isOp {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }
                HStack(spacing: 6) {
                    Text(player.gamemodeLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("\(player.ping)ms")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.3))
                .font(.footnote)
                .fontWeight(.semibold)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
    }
}

struct GlassResidentRow: View {
    let resident: ResidentPlayer
    let isOp: Bool
    let isOnline: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isOnline ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
                .shadow(color: isOnline ? .green : .gray, radius: 3)

            Text(resident.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(isOnline ? .white : .white.opacity(0.6))

            Spacer()

            if isOp {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }

            if !isOnline {
                Text("离线")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
    }
}

struct GlassOpRow: View {
    let op: OpPlayer

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .foregroundStyle(.yellow)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(Color.yellow.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(op.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text("权限等级: \(op.level)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            if op.bypassesPlayerLimit {
                Text("绕过人数限制")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
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
