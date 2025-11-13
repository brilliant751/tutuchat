import Foundation
import Combine

@MainActor
final class ChatsViewModel: ObservableObject {
    // View 订阅这些属性：变化就刷新 UI
    @Published private(set) var chats: [Chat] = []

    // 汇总未读（给 Tab 上的 badge 用）
    var totalUnread: Int {
        chats.reduce(0) { $0 + $1.unreadCount }
    }

    init() {
        loadMockData()
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
    }

    // 模拟数据（代替服务端）
    private func loadMockData() {
        let me = User(id: "me", nickname: "我")
        let a  = User(id: "u_a", nickname: "小明")
        let b  = User(id: "u_b", nickname: "Alice")
        let c  = User(id: "u_c", nickname: "张老师")

        // 从 20 分钟前开始，每条消息 +60s
        var t = Date().addingTimeInterval(-20 * 60)
        func nextTime(_ step: TimeInterval = 60) -> Date {
            defer { t = t.addingTimeInterval(step) }
            return t
        }

        func makeText(_ id: String, chatId: String, from: User, _ text: String, read: Bool) -> Message {
            Message(id: id, chatId: chatId, senderId: from.id,
                    sentAt: nextTime(), kind: .text(text), isRead: read)
        }

        var chat1 = Chat(id: "c1", peer: a)
        chat1.messages = [
            makeText("m1", chatId: "c1", from: a,  "明天去图书馆吗？", read: false),
            makeText("m2", chatId: "c1", from: me, "可以，下午两点。", read: true)
        ]
        chat1.unreadCount = chat1.messages.filter { !$0.isRead && $0.senderId != me.id }.count

        var chat2 = Chat(id: "c2", peer: b)
        chat2.messages = [
            makeText("m3", chatId: "c2", from: b,  "发你一张图片", read: false)
        ]
        chat2.unreadCount = 1

        var chat3 = Chat(id: "c3", peer: c)
        chat3.messages = [
            makeText("m4", chatId: "c3", from: c,  "周五交作业别忘了", read: true)
        ]
        chat3.unreadCount = 0

        chats = [chat1, chat2, chat3]
            .sorted { ($0.messages.last?.sentAt ?? .distantPast) > ($1.messages.last?.sentAt ?? .distantPast) }
    }

    
    // 读取某个会话的所有消息（按时间排序）
    func messages(for chatId: String) -> [Message] {
        guard let chat = chats.first(where: { $0.id == chatId }) else { return [] }
        return chat.messages.sorted { $0.sentAt < $1.sentAt }
    }

    // 发送文本消息
    func sendText(to chatId: String, text: String, from senderId: String = "me") {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let idx = chats.firstIndex(where: { $0.id == chatId }) else { return }
        var chat = chats[idx]

        let newMsg = Message(
            id: UUID().uuidString,
            chatId: chatId,
            senderId: senderId,
            sentAt: Date(),
            kind: .text(text),
            isRead: true // 本机发出的默认已读
        )
        chat.messages.append(newMsg)
        chats[idx] = chat
        // 发送后把该会话移动到顶部（按最后消息时间排序）
        chats.sort { ($0.messages.last?.sentAt ?? .distantPast) > ($1.messages.last?.sentAt ?? .distantPast) }
    }
    
    func sendImage(to chatId: String, data: Data, from senderId: String = "me") {
        guard let idx = chats.firstIndex(where: { $0.id == chatId }) else { return }
        var chat = chats[idx]

        let msg = Message(
            id: UUID().uuidString,
            chatId: chatId,
            senderId: senderId,
            sentAt: Date(),
            kind: .image(data),
            isRead: true
        )
        chat.messages.append(msg)
        chats[idx] = chat
        chats.sort { ($0.messages.last?.sentAt ?? .distantPast) > ($1.messages.last?.sentAt ?? .distantPast) }
    }


    // 进入会话时标记“对方消息”为已读
    func markChatMessagesReadOnOpen(_ chatId: String, me myId: String = "me") {
        guard let idx = chats.firstIndex(where: { $0.id == chatId }) else { return }
        var chat = chats[idx]
        var changed = false
        chat.messages = chat.messages.map { msg in
            var m = msg
            if m.senderId != myId && !m.isRead {
                m.isRead = true
                changed = true
            }
            return m
        }
        if changed {
            chat.unreadCount = 0
            chats[idx] = chat
        }
    }

}
