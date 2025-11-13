import SwiftUI

struct AlbumView: View {
    var body: some View {
        Text("相册（占位页）")
            .font(.title3).padding()
            .navigationTitle("相册")
    }
}

struct PayView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard").font(.largeTitle)
            Text("支付（占位页）")
        }
        .padding()
        .navigationTitle("支付")
    }
}

struct SettingsView: View {
    @State private var showReadReceipts = true
    @State private var savePhotosToAlbum = true

    var body: some View {
        Form {
            Section("聊天") {
                Toggle("已读回执", isOn: $showReadReceipts)
                Toggle("自动保存图片到相册", isOn: $savePhotosToAlbum)
            }
            Section("通用") {
                NavigationLink("外观与字体") { Text("外观与字体（占位）") }
                NavigationLink("通知与提醒") { Text("通知与提醒（占位）") }
            }
        }
        .navigationTitle("设置")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("TuTuChat").font(.title2).bold()
            Text("版本 0.1 (Multiplatform)").foregroundStyle(.secondary)
            Text("学习项目 · 仅前端 UI 演示").font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("关于")
    }
}
