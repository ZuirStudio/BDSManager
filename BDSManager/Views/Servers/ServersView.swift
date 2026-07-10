import SwiftUI

struct ServersView: View {
    @EnvironmentObject var store: ServerStore
    @State private var showAddSheet = false
    @State private var showManageSheet = false

    var body: some View {
        NavigationStack {
            List {
                if store.servers.isEmpty {
                    ContentUnavailableView("没有服务器", systemImage: "server.rack", description: Text("点击 + 添加一个服务器"))
                } else {
                    ForEach(store.servers) { server in
                        ServerRow(server: server, isActive: store.activeServerId == server.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.setActiveServer(server.id)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteServer(server)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }

                    if store.activeServer != nil {
                        Section {
                            NavigationLink {
                                ServerManageView()
                            } label: {
                                Label("服务器管理", systemImage: "gearshape")
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("服务器")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddServerView()
            }
        }
    }
}

struct ServerRow: View {
    let server: Server
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.title2)
                .foregroundStyle(isActive ? .blue : .secondary)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.headline)
                Text(server.displayAddress)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}
