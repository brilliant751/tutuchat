#if os(iOS)
import PhotosUI
#endif


import SwiftUI

struct ChatDetailView: View {
    @State private var showEmoji = false
    
#if os(iOS)
    @State private var pickedItem: PhotosPickerItem? = nil
#endif
    
    
    @EnvironmentObject var chatsVM: ChatsViewModel
    let chatId: String
    
    @State private var inputText: String = ""
    @FocusState private var focusedInput: Bool
    
    // 简化：每次渲染都从 VM 读取消息（保证是最新）
    private var messages: [Message] { chatsVM.messages(for: chatId) }
    private let myId = "me"
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                let rowWidth = proxy.size.width - 24   // 与下面的 .padding(.horizontal, 12) 对齐
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { msg in
                            let isMine = (msg.senderId == myId)
                            MessageBubbleView(isMine: isMine, kind: msg.kind)
                            // 关键：行宽 = 屏幕宽 - 外层左右边距；并用 alignment 贴左/右
                                .frame(width: rowWidth,
                                       alignment: isMine ? .trailing : .leading)
                                .id(msg.id)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)  // 统一控制左右留白
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // 底部输入条（先做文本 + 发送按钮）
            HStack(spacing: 8) {
                // ① Emoji 开关
                Button {
                    showEmoji.toggle()
                    if showEmoji { focusedInput = false } // 展示面板时收起键盘（iOS）
                } label: {
                    Image(systemName: "face.smiling")   // iOS/macOS 通用 SF Symbols
                        .font(.system(size: 20))
                }
                
                // ② 输入框
                TextField("发个消息…", text: $inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .focused($focusedInput)
                
                // ➕ 选图（平台分支）
#if os(iOS)
                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Image(systemName: "plus.circle").font(.system(size: 20))
                }
                .onChange(of: pickedItem) { _, item in
                    guard let item else { return }
                    Task { // 从相册异步取二进制
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            chatsVM.sendImage(to: chatId, data: data, from: myId)
                        }
                        pickedItem = nil
                    }
                }
#elseif os(macOS)
                Button {
                    pickImageOnMac()
                } label: {
                    Image(systemName: "plus.circle").font(.system(size: 20))
                }
#endif
                // ③ 发送
                Button("发送") {
                    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    chatsVM.sendText(to: chatId, text: text, from: myId)
                    inputText = ""
#if os(iOS)
                    focusedInput = true
#endif
                }
                .keyboardShortcut(.return, modifiers: []) // macOS: 回车发送
                .buttonStyle(.borderedProminent)
            }
            .padding(.all, 10)
            .background(Material.ultraThin)
            
            // ④ Emoji 面板（收起/展开）
            if showEmoji {
                EmojiPanel { emoji in
                    inputText += emoji
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(peerName)
        .navigationBarTitleDisplayMode(.inline)
#if os(iOS)
        .toolbar(.hidden, for: .tabBar) // 进入聊天隐藏底部 Tab（更像微信）
#endif
    }
#if os(macOS)
    private func pickImageOnMac() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic, .gif]
        panel.allowsMultipleSelection = false
        panel.begin { resp in
            guard resp == .OK, let url = panel.url,
                  let data = try? Data(contentsOf: url) else { return }
            chatsVM.sendImage(to: chatId, data: data, from: myId)
        }
    }
#endif

    
    private var peerName: String {
        chatsVM.chats.first(where: { $0.id == chatId })?.peer.nickname ?? "聊天"
    }
}
