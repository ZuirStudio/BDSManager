import SwiftUI

struct ConsoleView: View {
    @EnvironmentObject var store: ServerStore
    @State private var commandText = ""
    @FocusState private var isInputFocused: Bool

    private let quickCommands = [
        ("列表", "list"),
        ("TPS", "tps"),
        ("版本", "version"),
        ("帮助", "help"),
        ("白名单", "whitelist list"),
        ("管理员", "ops"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 快捷命令
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickCommands, id: \.1) { cmd in
                            Button {
                                Task { await store.executeCommand(cmd.1) }
                            } label: {
                                Text(cmd.0)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGroupedBackground))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                Divider()

                // 终端输出
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            if store.consoleMessages.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "terminal")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                    Text("输入命令开始使用")
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 60)
                            } else {
                                ForEach(store.consoleMessages) { msg in
                                    HStack(alignment: .top) {
                                        Text(msg.timestamp.formatted(date: .omitted, time: .shortened))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                            .frame(width: 50, alignment: .leading)

                                        Text(msg.content)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(messageColor(for: msg.type))
                                    }
                                    .id(msg.id)
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: store.consoleMessages.count) { _ in
                        if let last = store.consoleMessages.last {
                            withAnimation { proxy.scrollTo(last.id) }
                        }
                    }
                }

                Divider()

                // 命令输入
                HStack(spacing: 8) {
                    TextField("输入命令...", text: $commandText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .focused($isInputFocused)
                        .onSubmit { sendCommand() }

                    Button {
                        sendCommand()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(commandText.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            .navigationTitle("控制台")
        }
    }

    private func sendCommand() {
        guard !commandText.isEmpty else { return }
        let cmd = commandText
        commandText = ""
        Task { await store.executeCommand(cmd) }
    }

    private func messageColor(for type: ConsoleMessage.MessageType) -> Color {
        switch type {
        case .command: return .blue
        case .response: return .primary
        case .error: return .red
        case .info: return .secondary
        }
    }
}
