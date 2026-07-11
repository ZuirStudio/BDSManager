import SwiftUI

struct ServerManageView: View {
    @EnvironmentObject var store: ServerStore

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink {
                    ServerSettingsView()
                } label: {
                    GlassManageCard(icon: "gearshape", title: "服务器设置", subtitle: "修改配置", color: .blue)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    OpsListView()
                } label: {
                    GlassManageCard(icon: "crown", title: "管理员", subtitle: "OP 权限", color: .yellow)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    WhitelistView()
                } label: {
                    GlassManageCard(icon: "list.bullet.clipboard", title: "白名单", subtitle: "玩家管理", color: .green)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    BansView()
                } label: {
                    GlassManageCard(icon: "hammer", title: "封禁列表", subtitle: "封禁管理", color: .red)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PluginsManageView()
                } label: {
                    GlassManageCard(icon: "puzzlepiece.extension", title: "插件管理", subtitle: "Mod 管理", color: .orange)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    BackupManageView()
                } label: {
                    GlassManageCard(icon: "externaldrive", title: "备份管理", subtitle: "创建恢复", color: .purple)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    StatsView()
                } label: {
                    GlassManageCard(icon: "chart.bar", title: "性能统计", subtitle: "历史数据", color: .cyan)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .navigationTitle("服务器管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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

struct GlassManageCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .frame(height: 120)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
    }
}

// MARK: - 服务器设置
struct ServerSettingsView: View {
    @EnvironmentObject var store: ServerStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var host = ""
    @State private var port = ""
    @State private var rconPort = ""
    @State private var rconPassword = ""

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("名称", text: $name)
                TextField("地址", text: $host)
            }
            Section("端口") {
                TextField("游戏端口", text: $port)
                    .keyboardType(.numberPad)
                TextField("RCON 端口", text: $rconPort)
                    .keyboardType(.numberPad)
            }
            Section("RCON") {
                SecureField("密码", text: $rconPassword)
            }
        }
        .navigationTitle("服务器设置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let server = store.activeServer {
                name = server.name
                host = server.host
                port = String(server.port)
                rconPort = String(server.rconPort)
                rconPassword = server.rconPassword
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    if var server = store.activeServer {
                        server.name = name
                        server.host = host
                        server.port = Int(port) ?? 19132
                        server.rconPort = Int(rconPort) ?? 19132
                        server.rconPassword = rconPassword
                        store.updateServer(server)
                    }
                }
            }
        }
    }
}

// MARK: - 管理员列表
struct OpsListView: View {
    @EnvironmentObject var store: ServerStore
    @State private var showAddOp = false
    @State private var newOpName = ""

    var body: some View {
        List {
            if let server = store.activeServer, !server.ops.isEmpty {
                ForEach(server.ops) { op in
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading) {
                            Text(op.name)
                                .font(.headline)
                            Text("权限等级: \(op.level)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("取消OP") {
                            Task { await store.executeCommand("deop \(op.name)") }
                        }
                        .tint(.red)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            } else {
                ContentUnavailableView("没有管理员", systemImage: "crown", description: Text("点击添加管理员"))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("管理员列表")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddOp = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("添加管理员", isPresented: $showAddOp) {
            TextField("玩家名", text: $newOpName)
            Button("添加") {
                if !newOpName.isEmpty {
                    Task { await store.executeCommand("op \(newOpName)") }
                    newOpName = ""
                }
            }
            Button("取消", role: .cancel) { }
        }
    }
}

// MARK: - 白名单
struct WhitelistView: View {
    @EnvironmentObject var store: ServerStore
    @State private var showAdd = false
    @State private var newName = ""
    @State private var whitelist: [String] = ["Steve", "Alex", "Admin"]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(whitelist, id: \.self) { name in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(name)
                            .foregroundStyle(.white)
                        Spacer()
                        Button("移除") {
                            whitelist.removeAll { $0 == name }
                        }
                        .tint(.red)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .navigationTitle("白名单")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
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
        .alert("添加到白名单", isPresented: $showAdd) {
            TextField("玩家名", text: $newName)
            Button("添加") {
                if !newName.isEmpty { whitelist.append(newName); newName = "" }
            }
            Button("取消", role: .cancel) { }
        }
    }
}

// MARK: - 封禁列表
struct BansView: View {
    @State private var bannedPlayers: [(name: String, reason: String)] = [("BadPlayer", "恶意破坏")]
    @State private var showBan = false
    @State private var newBanName = ""

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(bannedPlayers, id: \.name) { player in
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        VStack(alignment: .leading) {
                            Text(player.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("原因: \(player.reason)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                        Button("解封") {
                            bannedPlayers.removeAll { $0.name == player.name }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .navigationTitle("封禁列表")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showBan = true } label: { Image(systemName: "plus") }
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
        .alert("封禁玩家", isPresented: $showBan) {
            TextField("玩家名", text: $newBanName)
            Button("封禁") {
                if !newBanName.isEmpty { bannedPlayers.append((newBanName, "管理员封禁")); newBanName = "" }
            }
            Button("取消", role: .cancel) { }
        }
    }
}

// MARK: - 插件管理
struct PluginsManageView: View {
    @EnvironmentObject var store: ServerStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.mods) { mod in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "puzzlepiece.extension")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading) {
                                Text(mod.name)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("v\(mod.version)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { mod.enabled },
                                set: { _ in store.toggleMod(mod) }
                            ))
                            .labelsHidden()
                            .tint(.orange)
                        }
                        if !mod.description.isEmpty {
                            Text(mod.description)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .navigationTitle("插件管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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

// MARK: - 备份管理
struct BackupManageView: View {
    @EnvironmentObject var store: ServerStore
    @State private var restoringId: UUID? = nil
    @State private var restoreProgress: Double = 0
    @State private var estimatedTime: Int = 0
    @State private var backupToDelete: BackupInfo? = nil
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if store.backups.isEmpty {
                    VStack {
                        ContentUnavailableView("没有备份", systemImage: "externaldrive", description: Text("点击下方创建备份"))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(store.backups) { backup in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "externaldrive")
                                    .foregroundStyle(.purple)
                                VStack(alignment: .leading) {
                                    Text(backup.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text("\(backup.size) · \(backup.date.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                Spacer()
                                Button(restoringId == backup.id ? "恢复中..." : "恢复") {
                                    startRestore(backup: backup)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(restoringId != nil)
                            }

                            if restoringId == backup.id {
                                ProgressView(value: restoreProgress, total: 100)
                                    .tint(.purple)
                                Text("\(Int(restoreProgress))% · 预计 \(estimatedTime)s")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                backupToDelete = backup
                                showDeleteConfirmation = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }

                Button {
                    let newBackup = BackupInfo(name: "手动备份", size: "\(Int.random(in: 100...150)) MB")
                    store.backups.insert(newBackup, at: 0)
                } label: {
                    Label("创建备份", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .navigationTitle("备份管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let backup = backupToDelete {
                    store.deleteBackup(backup)
                }
                backupToDelete = nil
            }
        } message: {
            Text("确定要删除备份 \"\(backupToDelete?.name ?? "")\" 吗？此操作不可撤销。")
        }
    }

    private func startRestore(backup: BackupInfo) {
        restoringId = backup.id
        restoreProgress = 0
        estimatedTime = 15

        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            restoreProgress += 1.34
            estimatedTime = max(Int((100 - restoreProgress) / 6.7), 0)

            if restoreProgress >= 100 {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    restoringId = nil
                }
            }
        }
    }
}

// MARK: - 性能统计
struct StatsView: View {
    let stats: [(label: String, value: String, icon: String)] = [
        ("最大玩家数", "24", "person.2"),
        ("当前在线", "8", "person.fill"),
        ("总游玩人数", "200", "person.crop.circle"),
        ("运行时长", "30天", "clock"),
        ("内存使用", "2.1 GB", "memorychip"),
        ("CPU 使用", "15%", "cpu"),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(stats, id: \.label) { stat in
                    VStack(spacing: 6) {
                        Image(systemName: stat.icon)
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        Text(stat.value)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text(stat.label)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .navigationTitle("性能统计")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
