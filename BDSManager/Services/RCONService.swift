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
    private var connectContinuationResumed = false
    private var receiveBuffer = Data()

    // MARK: - 连接
    func connect(host: String, port: Int, password: String) async throws -> Bool {
        self.host = host
        self.port = UInt16(port)
        self.password = password
        self.connectContinuationResumed = false
        self.receiveBuffer = Data()

        // 先清理旧连接
        connection?.cancel()
        connection = nil
        isConnected = false

        let nwHost = NWEndpoint.Host(host)
        guard let nwPort = NWEndpoint.Port(rawValue: self.port) else {
            throw RCONError.connectionFailed
        }
        let endpoint = NWEndpoint.hostPort(host: nwHost, port: nwPort)

        let parameters = NWParameters.tcp
        // 设置超时选项
        if let tcpOptions = parameters.defaultProtocolStack.transportProtocol as? NWProtocolTCP.Options {
            tcpOptions.connectionTimeout = 10
            tcpOptions.enableKeepalive = true
            tcpOptions.keepaliveIdle = 30
        }
        connection = NWConnection(to: endpoint, using: parameters)

        return try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            let resumeLock = NSLock()

            let safeResume: (Result<Bool, Error>) -> Void = { result in
                resumeLock.lock()
                let shouldResume = !resumed
                resumed = true
                resumeLock.unlock()
                if shouldResume {
                    switch result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            // 超时保护：15 秒后自动失败
            let timeoutWorkItem = DispatchWorkItem {
                safeResume(.failure(RCONError.timeout))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: timeoutWorkItem)

            connection?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    Task {
                        guard let self = self else {
                            timeoutWorkItem.cancel()
                            safeResume(.success(false))
                            return
                        }
                        await self.setConnected(true)
                        do {
                            let authResult = try await self.authenticate(password: password)
                            timeoutWorkItem.cancel()
                            safeResume(.success(authResult))
                        } catch {
                            timeoutWorkItem.cancel()
                            safeResume(.success(false))
                        }
                    }
                case .failed(let error):
                    timeoutWorkItem.cancel()
                    Task { await self?.setConnected(false) }
                    safeResume(.failure(error))
                case .waiting(let error):
                    // 等待状态可能是暂时的，但如果持续等待则超时会处理
                    print("RCON 连接等待中: \(error.localizedDescription)")
                case .setup, .preparing:
                    break
                case .cancelled:
                    timeoutWorkItem.cancel()
                    Task { await self?.setConnected(false) }
                    safeResume(.success(false))
                @unknown default:
                    break
                }
            }
            connection?.start(queue: .main)
        }
    }

    // MARK: - 认证
    private func authenticate(password: String) async throws -> Bool {
        // 空密码直接返回失败
        guard !password.isEmpty else {
            throw RCONError.authenticationFailed
        }

        // RCON 协议要求认证包的 id 必须是 0
        let authPacket = RCONPacket(id: 0, type: 3, body: password)
        let response = try await sendRawPacket(authPacket)

        // 认证成功时，服务器返回的包 type 为 2，id 为 0
        guard response.type == 2, response.id == 0 else {
            throw RCONError.authenticationFailed
        }
        isConnected = true
        requestId = 1 // 认证成功后，后续命令从 1 开始
        return true
    }

    // MARK: - 发送命令
    func sendCommand(_ command: String) async throws -> String {
        guard isConnected else { throw RCONError.notConnected }
        requestId &+= 1
        let packet = RCONPacket(id: requestId, type: 2, body: command)
        let response = try await sendRawPacket(packet)
        return response.body
    }

    // MARK: - 断开连接
    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
        receiveBuffer = Data()
    }

    // MARK: - 发送数据包
    private func sendRawPacket(_ packet: RCONPacket) async throws -> RCONPacket {

        guard let connection = connection else { throw RCONError.notConnected }
        guard connection.state == .ready else { throw RCONError.notConnected }

        let data = packet.encode()

        return try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            let resumeLock = NSLock()

            let safeResume: (Result<RCONPacket, Error>) -> Void = { result in
                resumeLock.lock()
                let shouldResume = !resumed
                resumed = true
                resumeLock.unlock()
                if shouldResume {
                    switch result {
                    case .success(let packet):
                        continuation.resume(returning: packet)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            // 超时保护：10 秒
            let timeoutWorkItem = DispatchWorkItem {
                safeResume(.failure(RCONError.timeout))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeoutWorkItem)

            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    timeoutWorkItem.cancel()
                    safeResume(.failure(error))
                    return
                }

                connection.receive(minimumIncompleteLength: 4, maximumLength: 4096) { content, _, isComplete, error in
                    timeoutWorkItem.cancel()

                    if let error = error {
                        safeResume(.failure(error))
                        return
                    }

                    if let data = content {
                        if let packet = RCONPacket.decode(data) {
                            safeResume(.success(packet))
                        } else {
                            // 数据不完整，尝试再读取一次
                            connection.receive(minimumIncompleteLength: 4, maximumLength: 4096) { content2, _, _, error2 in
                                if let error2 = error2 {
                                    safeResume(.failure(error2))
                                    return
                                }
                                if let data2 = content2 {
                                    var combined = data
                                    combined.append(data2)
                                    if let packet = RCONPacket.decode(combined) {
                                        safeResume(.success(packet))
                                    } else {
                                        safeResume(.success(RCONPacket(id: -1, type: -1, body: "")))
                                    }
                                } else {
                                    safeResume(.success(RCONPacket(id: -1, type: -1, body: "")))
                                }
                            }
                        }
                    } else if isComplete {
                        safeResume(.failure(RCONError.notConnected))
                    } else {
                        safeResume(.success(RCONPacket(id: -1, type: -1, body: "")))
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
        // 使用安全的方式写入小端字节
        data.append(UInt8(truncatingIfNeeded: length))
        data.append(UInt8(truncatingIfNeeded: length >> 8))
        data.append(UInt8(truncatingIfNeeded: length >> 16))
        data.append(UInt8(truncatingIfNeeded: length >> 24))
        data.append(UInt8(truncatingIfNeeded: id))
        data.append(UInt8(truncatingIfNeeded: id >> 8))
        data.append(UInt8(truncatingIfNeeded: id >> 16))
        data.append(UInt8(truncatingIfNeeded: id >> 24))
        data.append(UInt8(truncatingIfNeeded: type))
        data.append(UInt8(truncatingIfNeeded: type >> 8))
        data.append(UInt8(truncatingIfNeeded: type >> 16))
        data.append(UInt8(truncatingIfNeeded: type >> 24))
        data.append(bodyData)
        data.append(0x00)
        data.append(0x00)
        return data
    }

    static func decode(_ data: Data) -> RCONPacket? {
        // 最小 RCON 包：4(长度) + 4(id) + 4(type) + 2(空body终止符) = 14 字节
        guard data.count >= 14 else { return nil }

        // 安全读取 length（前4字节，小端）
        let length = Int(readInt32(data, offset: 0))
        guard length >= 10, length <= 4096 else { return nil }

        // 验证数据长度是否足够（length 字段不包含自身4字节）
        let expectedTotal = length + 4
        guard data.count >= expectedTotal else { return nil }

        let id = readInt32(data, offset: 4)
        let type = readInt32(data, offset: 8)

        // body 区域：从 offset 12 开始，长度为 length - 4(id) - 4(type) - 2(终止符)
        let bodyLength = length - 10
        guard bodyLength >= 0 else { return nil }

        let bodyEnd = 12 + bodyLength
        guard bodyEnd <= data.count else { return nil }

        let bodyData = data.subdata(in: 12..<bodyEnd)
        let body = String(data: bodyData, encoding: .utf8) ?? ""

        return RCONPacket(id: id, type: type, body: body)
    }

    private static func readInt32(_ data: Data, offset: Int) -> Int32 {
        guard offset + 4 <= data.count else { return 0 }
        let b0 = Int32(data[data.startIndex + offset])
        let b1 = Int32(data[data.startIndex + offset + 1]) << 8
        let b2 = Int32(data[data.startIndex + offset + 2]) << 16
        let b3 = Int32(data[data.startIndex + offset + 3]) << 24
        return b0 | b1 | b2 | b3
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
        case .authenticationFailed: return "RCON 认证失败，请检查密码"
        case .connectionFailed: return "连接失败，请检查地址和端口"
        case .timeout: return "连接超时，服务器未响应"
        }
    }
}
