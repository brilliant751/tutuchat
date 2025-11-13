import SwiftUI

struct ChatsView: View {
    @EnvironmentObject var vm: ChatsViewModel   // ← 从环境取 ViewModel

    var body: some View {
        NavigationStack {
            List(vm.chats) { chat in
                NavigationLink(value: chat.id) {
                    ChatRowView(chat: chat)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {   // iOS 上可滑动（macOS 会忽略）
                    Button("已读") { vm.markChatAsRead(chat.id) }
                        .tint(.blue)
                }
            }
            .listStyle(.plain)
            .navigationTitle("微信")
            // 先放一个空的导航目的地，下一步再做单聊页
            .navigationDestination(for: String.self) { chatId in
                        ChatDetailView(chatId: chatId)
                            .environmentObject(vm) // 传入同一个 VM
            }
        }
    }
}
