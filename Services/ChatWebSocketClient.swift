import Foundation

struct SocketMessage: Codable {
    enum MessageType: String, Codable {
        case join = "JOIN"
        case chat = "CHAT"
        case system = "SYSTEM"
        case ping = "PING"
        case pong = "PONG"
    }

    var type: MessageType
    var roomId: String?
    var from: String?
    var content: String?
    var timestamp: Int64?
    var errorCode: String?
    var users: [String]?
}

final class ChatWebSocketClient: NSObject {
    enum State {
        case disconnected
        case connecting
        case connected
    }

    private(set) var state: State = .disconnected {
        didSet { onStateChange?(state) }
    }
    private(set) var joinedRoomId: String?

    var onMessage: ((SocketMessage) -> Void)?
    var onStateChange: ((State) -> Void)?

    private var token: String?
    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    func connectIfNeeded(token: String) {
        guard state == .disconnected || self.token != token else { return }
        self.token = token

        if let task = webSocketTask {
            task.cancel(with: .goingAway, reason: nil)
        }

        var components = URLComponents(string: "ws://47.114.86.161:12345/ws/chat")
        components?.queryItems = [URLQueryItem(name: "token", value: token)]
        guard let url = components?.url else {
            return
        }

        state = .connecting
        let task = urlSession.webSocketTask(with: url)
        webSocketTask = task
        task.resume()
        state = .connected
        receiveLoop()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        state = .disconnected
        joinedRoomId = nil
    }

    func join(roomId: String) {
        guard case .connected = state else { return }
        joinedRoomId = roomId
        let joinMsg = SocketMessage(type: .join, roomId: roomId, from: nil, content: nil, timestamp: nil, errorCode: nil, users: nil)
        send(joinMsg)
    }

    func sendChat(roomId: String, content: String) {
        guard case .connected = state else { return }
        let msg = SocketMessage(type: .chat, roomId: roomId, from: nil, content: content, timestamp: nil, errorCode: nil, users: nil)
        send(msg)
    }

    private func send(_ message: SocketMessage) {
        guard let task = webSocketTask else { return }
        guard let data = try? JSONEncoder().encode(message),
              let json = String(data: data, encoding: .utf8) else { return }
        task.send(.string(json)) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }

    private func receiveLoop() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self.state = .disconnected
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let socketMessage = try? JSONDecoder().decode(SocketMessage.self, from: data) {
                        self.onMessage?(socketMessage)
                    }
                case .data(let data):
                    if let socketMessage = try? JSONDecoder().decode(SocketMessage.self, from: data) {
                        self.onMessage?(socketMessage)
                    }
                @unknown default:
                    break
                }
                self.receiveLoop()
            }
        }
    }
}
