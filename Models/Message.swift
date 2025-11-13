import Foundation

enum MessageKind: Hashable {
    case text(String)
    case image(Data)        // 本地或远程图片 URL（先用本地占位）
    case video(URL)        // 预留：朋友圈/聊天可用
}

struct Message: Identifiable, Hashable {
    let id: String
    let chatId: String
    let senderId: String
    let sentAt: Date
    var kind: MessageKind
    var isRead: Bool
}
