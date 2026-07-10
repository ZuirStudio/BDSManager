import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: ServerStore

    var body: some View {
        TabView {
            ServersView()
                .tabItem {
                    Label("服务器", systemImage: "server.rack")
                }

            StatusView()
                .tabItem {
                    Label("状态", systemImage: "chart.bar")
                }

            PlayersView()
                .tabItem {
                    Label("玩家", systemImage: "person.2")
                }

            ConsoleView()
                .tabItem {
                    Label("控制台", systemImage: "terminal")
                }
        }
        .tint(.blue)
    }
}
