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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickCommands, id: \.1) { cmd in
                            Button {
                                Task { await store.executeCommand(cmd.1) }
                            } label: {
                                Text(cmd.0)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            if store.consoleMessages.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "terminal")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.white.opacity(0.5))
                                    Text("输入命令开始使用")
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            } else {
                                ForEach(store.consoleMessages) { msg in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text(msg.timestamp.formatted(date: .omitted, time: .shortened))
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.3))
                                            .frame(width: 50, alignment: .leading)

                                        Text(msg.content)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(messageColor(for: msg.type))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(msg.type == .command ? Color.blue.opacity(0.1) : (msg.type == .error ? Color.red.opacity(0.1) : Color.clear))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                    .background(Color.white.opacity(0.1))

                HStack(spacing: 8) {
                    TextField("输入命令...", text: $commandText)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .focused($isInputFocused)
                        .onSubmit { sendCommand() }

                    Button {
                        sendCommand()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(commandText.isEmpty ? .white.opacity(0.3) : .blue)
                    }
                    .disabled(commandText.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("控制台")
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

    private func sendCommand() {
        guard !commandText.isEmpty else { return }
        let cmd = commandText
        commandText = ""
        Task { await store.executeCommand(cmd) }
    }

    private func messageColor(for type: ConsoleMessage.MessageType) -> Color {
        switch type {
        case .command: return .blue
        case .response: return .white
        case .error: return .red
        case .info: return .white.opacity(0.6)
        }
    }
}
