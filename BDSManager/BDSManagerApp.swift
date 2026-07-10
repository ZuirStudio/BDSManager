import SwiftUI

@main
struct BDSManagerApp: App {
    @StateObject var store = ServerStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
        }
    }
}
