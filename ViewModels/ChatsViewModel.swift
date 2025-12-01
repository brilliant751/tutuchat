import Foundation
import Combine

@MainActor
final class ChatsViewModel: ObservableObject {
    // View 订阅这些属性：变化就刷新 UI
    @Published private(set) var chats: [Chat] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // 汇总未读（给 Tab 上的 badge 用）
    var totalUnread: Int {
        chats.reduce(0) { $0 + $1.unreadCount }
    }

    var myUserId: String { currentUserId }

    private var authToken: String?
    private var currentUserId: String = "me"
    private var currentUsername: String = "me"
    private var lastSyncedToken: String?
    private var joinedRoomId: String?
    private let socketClient = ChatWebSocketClient()

    init() {
        socketClient.onMessage = { [weak self] message in
            Task { @MainActor in
                self?.handleSocketMessage(message)
            }
        }
    }

    func syncFromServer(session: AuthSession) async {
        if lastSyncedToken == session.token && !chats.isEmpty { return }
        isLoading = true
        errorMessage = nil
        authToken = session.token
        currentUserId = String(session.userId)
        currentUsername = session.username
        socketClient.connectIfNeeded(token: session.token)
        do {
            let summaries = try await ChatService.fetchMyChats(token: session.token)
            var loadedChats: [Chat] = []
            for summary in summaries {
                let msgs = try await ChatService.fetchMessages(chatId: summary.chatId, token: session.token)
                let mappedMessages = msgs.map { remote in
                    Message(
                        id: String(remote.id),
                        chatId: String(remote.chatId),
                        senderId: String(remote.senderId),
                        sentAt: remote.createdAt,
                        kind: .text(remote.content),
                        isRead: true
                    )
                }
                let title = (summary.title?.isEmpty == false) ? summary.title! : "会话\(summary.chatId)"
                var chat = Chat(id: String(summary.chatId),
                                peer: User(id: "chat-\(summary.chatId)", nickname: title))
                chat.messages = mappedMessages
                chat.unreadCount = Int(summary.unreadCount)
                loadedChats.append(chat)
            }
            chats = loadedChats
                .sorted { ($0.messages.last?.sentAt ?? .distantPast) > ($1.messages.last?.sentAt ?? .distantPast) }
            lastSyncedToken = session.token
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func markChatAsRead(_ chatId: String) {
        guard let idx = chats.firstIndex(where: { $0.id == chatId }) else { return }
        var chat = chats[idx]
        // 将该会话的所有消息置已读，并清零未读
        chat.messages = chat.messages.map { msg in
            var m = msg
            m.isRead = true
            return m
        }
        chat.unreadCount = 0
        chats[idx] = chat

        if let token = authToken {
            Task {
                guard let chatIdInt = Int64(chatId) else { return }
                let lastId = chat.messages.last.flatMap { Int64($0.id) }
                try? await ChatService.markChatRead(chatId: chatIdInt, lastReadMessageId: lastId, token: token)
            }
        }
    }


    // 读取某个会话的所有消息（按时间排序）
    func messages(for chatId: String) -> [Message] {
        guard let chat = chats.first(where: { $0.id == chatId }) else { return [] }
        return chat.messages.sorted { $0.sentAt < $1.sentAt }
    }

    // 发送文本消息
    func sendText(to chatId: String, text: String, from senderId: String? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let idx = chats.firstIndex(where: { $0.id == chatId }) else { return }
        var chat = chats[idx]

        let sender = senderId ?? currentUserId
        // 如果已加入房间则走 WebSocket 发送，由服务器广播回来；否则本地直接插入一条
        if socketClient.state == .connected && socketClient.joinedRoomId == chatId {
            socketClient.sendChat(roomId: chatId, content: text)
        } else {
            let newMsg = Message(
                id: UUID().uuidString,
                chatId: chatId,
                senderId: sender,
                sentAt: Date(),
                kind: .text(text),
                isRead: true // 本机发出的默认已读
            )
            chat.messages.append(newMsg)
            chats[idx] = chat
            // 发送后把该会话移动到顶部（按最后消息时间排序）
            chats.sort { ($0.messages.last?.sentAt ?? .distantPast) > ($1.messages.last?.sentAt ?? .distantPast) }
        }
    }
    
    func sendImage(to chatId: String, data: Data, from senderId: String? = nil) {
        guard let idx = chats.firstIndex(where: { $0.id == chatId }) else { return }
        var chat = chats[idx]

        let sender = senderId ?? currentUserId
        let msg = Message(
            id: UUID().uuidString,
            chatId: chatId,
            senderId: sender,
            sentAt: Date(),
            kind: .image(data),
            isRead: true
        )
        chat.messages.append(msg)
        chats[idx] = chat
        chats.sort { ($0.messages.last?.sentAt ?? .distantPast) > ($1.messages.last?.sentAt ?? .distantPast) }
    }


    // 进入会话时标记“对方消息”为已读
    func markChatMessagesReadOnOpen(_ chatId: String, me myId: String? = nil) {
        guard let idx = chats.firstIndex(where: { $0.id == chatId }) else { return }
        let myId = myId ?? currentUserId
        var chat = chats[idx]
        var changed = false
        chat.messages = chat.messages.map { msg in
            var m = msg
            if !isMine(m.senderId) && !m.isRead {
                m.isRead = true
                changed = true
            }
            return m
        }
        if changed {
            chat.unreadCount = 0
            chats[idx] = chat
            if let token = authToken {
                Task {
                    guard let chatIdInt = Int64(chatId) else { return }
                    let lastId = chat.messages.last.flatMap { Int64($0.id) }
                    try? await ChatService.markChatRead(chatId: chatIdInt, lastReadMessageId: lastId, token: token)
                }
            }
        }
    }

}

// MARK: - WebSocket
extension ChatsViewModel {
    func joinChatRoom(_ chatId: String, session: AuthSession) {
        authToken = session.token
        currentUserId = String(session.userId)
        currentUsername = session.username
        socketClient.connectIfNeeded(token: session.token)
        socketClient.join(roomId: chatId)
        joinedRoomId = chatId
    }

    func isMine(_ senderId: String) -> Bool {
        senderId == currentUserId || senderId == currentUsername
    }

    private func handleSocketMessage(_ message: SocketMessage) {
        switch message.type {
        case .chat:
            guard let roomId = message.roomId else { return }
            let sender = message.from ?? "未知"
            let content = message.content ?? ""
            let ts = message.timestamp.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? Date()
            var msg = Message(id: UUID().uuidString,
                              chatId: roomId,
                              senderId: sender,
                              sentAt: ts,
                              kind: .text(content),
                              isRead: isMine(sender))
            guard let idx = chats.firstIndex(where: { $0.id == roomId }) else {
                return
            }
            var chat = chats[idx]
            chat.messages.append(msg)
            if !isMine(sender) {
                chat.unreadCount += 1
            }
            chats[idx] = chat
            chats.sort { ($0.messages.last?.sentAt ?? .distantPast) > ($1.messages.last?.sentAt ?? .distantPast) }
        case .system, .ping, .pong, .join:
            break
        }
    }
}
