import Foundation

struct Chat: Identifiable, Hashable {
    let id: String
    var peer: User                  // 单聊对象（群聊后续可以扩展为 [User]）
    var messages: [Message] = []
    var unreadCount: Int = 0

    var lastMessagePreview: String {
        if let last = messages.last {
            switch last.kind {
            case .text(let s): return s
            case .image:       return "[图片]"
            case .video:       return "[视频]"
            }
        }
        return ""
    }

    var lastTimeString: String {
        guard let last = messages.last else { return "" }
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: last.sentAt)
    }
}
