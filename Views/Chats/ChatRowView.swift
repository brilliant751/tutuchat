import SwiftUI

struct ChatRowView: View {
    let chat: Chat

    var body: some View {
        HStack(spacing: 12) {
            // 头像（先用首字母圆形占位）
            ZStack {
                Circle().fill(Color.gray.opacity(0.2))
                Text(String(chat.peer.nickname.prefix(1)))
                    .font(.system(size: 18, weight: .medium))
            }
            .frame(width: 48, height: 48)
            .overlay(alignment: .topTrailing) {
                if chat.unreadCount > 0 {
                    // 右上角红点
                    Text("\(min(chat.unreadCount, 99))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                        .offset(x: 6, y: -6)
                }
            }

            // 中间：昵称 + 最后一条消息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.peer.nickname)
                        .font(.system(size: 17, weight: .medium))
                    Spacer()
                    Text(chat.lastTimeString)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }
                Text(chat.lastMessagePreview)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .font(.system(size: 14))
            }
        }
        .contentShape(Rectangle()) // 提高可点区域
        .padding(.vertical, 6)
    }
}
