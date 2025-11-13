import SwiftUI

struct EmojiPanel: View {
    let onPick: (String) -> Void

    // 常用一页 6x4 的小集合，后面你可以再扩充
    private let emojis: [String] = [
        "😀","😁","😂","🤣","😊","😍",
        "🤔","😎","😭","😡","👍","🙏",
        "🎉","🔥","❤️","💯","🍕","☕️",
        "📚","✈️","🖥️","📷","🐶","🌙"
    ]

    // 网格布局：每行 6 个
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(emojis, id: \.self) { e in
                Button {
                    onPick(e)
                } label: {
                    Text(e).font(.system(size: 28))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThickMaterial)
        .frame(maxHeight: 240) // 面板高度
    }
}
