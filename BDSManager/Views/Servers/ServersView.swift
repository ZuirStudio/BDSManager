import SwiftUI

struct ServersView: View {
    @EnvironmentObject var store: ServerStore
    @State private var showAddSheet = false
    @State private var showManageSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if store.servers.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "server.rack")
                                .font(.system(size: 60))
                                .foregroundStyle(.white.opacity(0.6))
                            Text("没有服务器")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            Text("点击 + 添加一个服务器")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        ForEach(store.servers) { server in
                            NavigationLink {
                                ServerManageView()
                                    .onAppear {
                                        store.setActiveServer(server.id)
                                    }
                            } label: {
                                GlassServerRow(server: server, isActive: store.activeServerId == server.id)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    store.deleteServer(server)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .navigationTitle("服务器")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddServerView()
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
}

struct GlassServerRow: View {
    let server: Server
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "server.rack")
                .font(.title2)
                .foregroundStyle(isActive ? .blue : .white.opacity(0.6))
                .frame(width: 44, height: 44)
                .background(isActive ? Color.blue.opacity(0.2) : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(server.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(server.displayAddress)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
            }

            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.3))
                .font(.footnote)
                .fontWeight(.semibold)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isActive ? Color.blue.opacity(0.5) : Color.white.opacity(0.08), lineWidth: isActive ? 1.5 : 0.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
    }
}
