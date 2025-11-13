// MessageBubbleView.swift
import SwiftUI

struct MessageBubbleView: View {
    let isMine: Bool
    let kind: MessageKind
    
    var body: some View {
        content
            .padding(.horizontal, 12)   // ← 气泡内部 padding，保留
            .padding(.vertical, 8)
            .background(isMine ? Color.accentColor : Color(.systemGray6))
            .foregroundStyle(isMine ? Color.white : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .frame(maxWidth: 280, alignment: isMine ? .trailing : .leading) // 气泡最大宽
            .padding(.vertical, 2)      // ← 只保留纵向外边距
        // 这里不要再加横向 padding
    }
    
    @ViewBuilder
    private var content: some View {
        switch kind {
        case .text(let s):
            Text(s)
                .font(.system(size: 16))
                .multilineTextAlignment(.leading)

        case .image(let data):
            if let img = platformImage(from: data) {
                img
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 160)   // 简单缩略图
                    .clipped()
                    .cornerRadius(10)
            } else {
                Text("[图片加载失败]").font(.footnote)
            }

        case .video:
            Text("[视频]")
        }
    }

    // 平台无关：把 Data 转 SwiftUI.Image
    private func platformImage(from data: Data) -> Image? {
        #if os(iOS)
        if let ui = UIImage(data: data) { return Image(uiImage: ui) }
        #elseif os(macOS)
        if let ns = NSImage(data: data) { return Image(nsImage: ns) }
        #endif
        return nil
    }

}
