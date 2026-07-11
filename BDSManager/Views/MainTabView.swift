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
