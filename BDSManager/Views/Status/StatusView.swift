import SwiftUI

struct StatusView: View {
    @EnvironmentObject var store: ServerStore

    var body: some View {
        NavigationStack {
            List {
                // 连接状态
                Section("服务器状态") {
                    HStack {
                        Circle()
                            .fill(store.connectionStatus == .connected ? .green : (store.connectionStatus == .connecting ? .yellow : .red))
                            .frame(width: 10, height: 10)
                        Text(store.connectionStatus.label)
                        Spacer()
                        if store.connectionStatus == .connected {
                            Button("断开") { store.disconnectServer() }
                                .tint(.red)
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        } else {
                            Button("连接") { Task { await store.connectToServer() } }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }
                }

                // 数据统计
                Section("数据统计") {
                    HStack {
                        StatItem(title: "TPS", value: String(format: "%.1f", store.serverTPS), color: store.serverTPS >= 18 ? .green : .red)
                        StatItem(title: "在线", value: "\(store.onlinePlayers.count)", color: .blue)
                        StatItem(title: "版本", value: store.serverVersion, color: .secondary)
                    }
                }

                // 服务器信息
                Section("服务器信息") {
                    LabeledContent("版本", value: store.serverVersion)
                    LabeledContent("存档名称", value: store.serverLevelName)
                    LabeledContent("在线玩家", value: "\(store.onlinePlayers.count)/20")
                }

                // Mod 管理
                Section {
                    NavigationLink {
                        ModManageView()
                    } label: {
                        HStack {
                            Image(systemName: "puzzlepiece.extension")
                                .foregroundStyle(.blue)
                            Text("Mod/插件管理")
                            Spacer()
                            Text("\(store.mods.filter { $0.enabled }.count)/\(store.mods.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("状态")
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ModManageView: View {
    @EnvironmentObject var store: ServerStore

    var body: some View {
        List {
            ForEach(store.mods) { mod in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(mod.name)
                            .font(.headline)
                        Text("v\(mod.version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { mod.enabled },
                            set: { _ in store.toggleMod(mod) }
                        ))
                        .labelsHidden()
                        .tint(.blue)
                    }
                    if !mod.description.isEmpty {
                        Text(mod.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if !mod.author.isEmpty {
                        Text("作者: \(mod.author)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Mod/插件管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}
