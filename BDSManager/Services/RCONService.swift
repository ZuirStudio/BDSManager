import Foundation
import Network

// MARK: - RCON 协议实现
actor RCONService {
    private var connection: NWConnection?
    private var requestId: Int32 = 0
    private var isConnected = false
    private var host: String = ""
    private var port: UInt16 = 19132
    private var password: String = ""

    // MARK: - 连接
    func connect(host: String, port: Int, password: String) async throws -> Bool {
        self.host = host
        self.port = UInt16(port)
        self.password = password

        let nwHost = NWEndpoint.Host(host)
        guard let nwPort = NWEndpoint.Port(rawValue: self.port) else {
            throw RCONError.connectionFailed
        }
        let endpoint = NWEndpoint.hostPort(host: nwHost, port: nwPort)

        let parameters = NWParameters.tcp
        connection = NWConnection(to: endpoint, using: parameters)

        return try await withCheckedThrowingContinuation { continuation in
            connection?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    Task {
                        await self?.setConnected(true)
                        do {
                            let authResult = try await self?.authenticate(password: password) ?? false
                            continuation.resume(returning: authResult)
                        } catch {
                            continuation.resume(returning: false)
                        }
                    }
                case .failed(let error):
                    Task { await self?.setConnected(false) }
                    continuation.resume(throwing: error)
                case .waiting, .setup, .preparing:
                    break
                case .cancelled:
                    Task { await self?.setConnected(false) }
                    continuation.resume(returning: false)
                @unknown default:
                    break
                }
            }
            connection?.start(queue: .main)
        }
    }

    // MARK: - 认证
    private func authenticate(password: String) async throws -> Bool {
        requestId = 0
        let response = try await sendPacket(type: 3, body: password)
        guard response.type == 2 else { return false }
        isConnected = true
        return true
    }

    // MARK: - 发送命令
    func sendCommand(_ command: String) async throws -> String {
        guard isConnected else { throw RCONError.notConnected }
        let response = try await sendPacket(type: 2, body: command)
        return response.body
    }

    // MARK: - 断开连接
    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
    }

    // MARK: - 发送数据包
    private func sendPacket(type: Int32, body: String) async throws -> RCONPacket {
        requestId &+= 1
        let packet = RCONPacket(id: requestId, type: type, body: body)

        guard let connection = connection else { throw RCONError.notConnected }

        let data = packet.encode()

        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                connection.receive(minimumIncompleteLength: 4, maximumLength: 4096) { content, _, isComplete, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    if let data = content, let packet = RCONPacket.decode(data) {
                        continuation.resume(returning: packet)
                    } else {
                        continuation.resume(returning: RCONPacket(id: -1, type: -1, body: "解析响应失败"))
                    }
                }
            })
        }
    }

    // MARK: - 获取状态
    func getConnectionStatus() -> Bool {
        isConnected
    }

    // MARK: - 设置连接状态（actor 内部调用）
    private func setConnected(_ value: Bool) {
        isConnected = value
    }
}

// MARK: - RCON 数据包
struct RCONPacket {
    let id: Int32
    let type: Int32
    let body: String

    func encode() -> Data {
        let bodyData = body.data(using: .utf8) ?? Data()
        let length: Int32 = Int32(4 + 4 + bodyData.count + 2)
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: length.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: id.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: type.littleEndian) { Array($0) })
        data.append(bodyData)
        data.append(contentsOf: [0x00, 0x00])
        return data
    }

    static func decode(_ data: Data) -> RCONPacket? {
        guard data.count >= 14 else { return nil }
        let length = data[0..<4].withUnsafeBytes { $0.load(as: Int32.self).littleEndian }
        let id = data[4..<8].withUnsafeBytes { $0.load(as: Int32.self).littleEndian }
        let type = data[8..<12].withUnsafeBytes { $0.load(as: Int32.self).littleEndian }
        let bodyData = data[12..<(Int(length) + 4 - 2)]
        let body = String(data: bodyData, encoding: .utf8) ?? ""
        return RCONPacket(id: id, type: type, body: body)
    }
}

// MARK: - 错误类型
enum RCONError: LocalizedError {
    case notConnected
    case authenticationFailed
    case connectionFailed
    case timeout

    var errorDescription: String? {
        switch self {
        case .notConnected: return "未连接到服务器"
        case .authenticationFailed: return "RCON 认证失败"
        case .connectionFailed: return "连接失败"
        case .timeout: return "连接超时"
        }
    }
}
