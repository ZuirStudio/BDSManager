import SwiftUI

struct StatusView: View {
    @EnvironmentObject var store: ServerStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    connectionCard
                    statsCard
                    infoCard
                    modCard
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .navigationTitle("状态")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .font(.title2)
                    .foregroundStyle(store.connectionStatus == .connected ? .green : (store.connectionStatus == .connecting ? .yellow : .red))
                Text("服务器状态")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack {
                Circle()
                    .fill(store.connectionStatus == .connected ? .green : (store.connectionStatus == .connecting ? .yellow : .red))
                    .frame(width: 10, height: 10)
                    .shadow(color: store.connectionStatus == .connected ? .green : (store.connectionStatus == .connecting ? .yellow : .red), radius: 4)
                Text(store.connectionStatus.label)
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                if store.connectionStatus == .connected {
                    Button("断开") { store.disconnectServer() }
                        .tint(.red)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                } else if store.connectionStatus != .connecting {
                    Button("连接") { Task { await store.connectToServer() } }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }

            if store.connectionStatus == .connecting {
                ProgressView()
                    .tint(.yellow)
            }

            if let error = store.lastError, store.connectionStatus == .disconnected {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red.opacity(0.9))
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("数据统计")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack(spacing: 12) {
                GlassStatItem(title: "TPS", value: String(format: "%.1f", store.serverTPS), color: store.serverTPS >= 18 || store.serverTPS == 0 ? .green : .red, icon: "speedometer")
                GlassStatItem(title: "在线", value: "\(store.onlinePlayers.count)", color: .blue, icon: "person.2.fill")
                GlassStatItem(title: "版本", value: store.serverVersion, color: .purple, icon: "info.circle.fill")
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "server.rack")
                    .font(.title2)
                    .foregroundStyle(.cyan)
                Text("服务器信息")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Spacer()
            }

            VStack(spacing: 10) {
                infoRow(label: "版本", value: store.serverVersion)
                Divider().background(Color.white.opacity(0.1))
                infoRow(label: "存档名称", value: store.serverLevelName)
                Divider().background(Color.white.opacity(0.1))
                infoRow(label: "在线玩家", value: "\(store.onlinePlayers.count)/20")
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }

    private var modCard: some View {
        NavigationLink {
            ModManageView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Mod/插件管理")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Text("\(store.mods.filter { $0.enabled }.count)/\(store.mods.count) 个已启用")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.4))
                    .font(.footnote)
                    .fontWeight(.semibold)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .foregroundStyle(.white)
                .fontWeight(.medium)
        }
    }
}

struct GlassStatItem: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ModManageView: View {
    @EnvironmentObject var store: ServerStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if store.mods.isEmpty {
                    ContentUnavailableView("没有 Mod/插件", systemImage: "puzzlepiece.extension")
                        .padding(.top, 60)
                } else {
                    ForEach(store.mods) { mod in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(mod.name)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                Text("v\(mod.version)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
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
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            if !mod.author.isEmpty {
                                Text("作者: \(mod.author)")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .navigationTitle("Mod/插件管理")
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
