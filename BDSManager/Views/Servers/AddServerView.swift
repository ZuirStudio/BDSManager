import SwiftUI

struct AddServerView: View {
    @EnvironmentObject var store: ServerStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var host = ""
    @State private var port = "19132"
    @State private var rconPort = "19132"
    @State private var rconPassword = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $name)
                    TextField("地址", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
            .navigationTitle("添加服务器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let server = Server(
                            name: name,
                            host: host,
                            port: Int(port) ?? 19132,
                            rconPort: Int(rconPort) ?? 19132,
                            rconPassword: rconPassword
                        )
                        store.addServer(server)
                        store.setActiveServer(server.id)
                        dismiss()
                    }
                    .disabled(name.isEmpty || host.isEmpty)
                }
            }
        }
    }
}
