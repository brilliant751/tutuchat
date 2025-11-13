import SwiftUI

struct MomentsView: View {
    @StateObject private var vm = MomentsViewModel()

    var body: some View {
        GeometryReader { proxy in
            // 列表内容的实际可用宽：去掉左右 inset 16+16
            let contentWidth = proxy.size.width - 32

            List {
                if let err = vm.errorText {
                    Text("加载失败：\(err)").foregroundStyle(.red)
                }
                ForEach(vm.moments) { m in
                    MomentRow(moment: m, contentWidth: contentWidth)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }
            }
            .listStyle(.plain)
            .navigationTitle("朋友圈")
            .toolbar { Button("刷新") { vm.load() } }
        }
    }
}

struct MomentRow: View {
    let moment: Moment
    let contentWidth: CGFloat
    @State private var showPreview = false
    @State private var startIndex = 0
    private let grid = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 头部：头像 + 名字 + 时间
            header
            
            if let t = moment.text, !t.isEmpty { Text(t).font(.body) }
            
            if let imgs = moment.images, !imgs.isEmpty {
                ResponsiveGrid(width: contentWidth, images: imgs) { tappedIndex in
                    startIndex = tappedIndex
                    showPreview = true
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)   // ← 这一行很重要
            }
            if moment.videoURL != nil {
                videoPlaceholder
            }
        }
    }
    
    var header: some View{
        HStack(spacing: 12) {
            Circle().fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(Text(String(moment.userName.prefix(1))).font(.headline))
            VStack(alignment: .leading, spacing: 2) {
                Text(moment.userName).font(.subheadline).bold()
                Text(Self.format(moment.createdAt)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    private var videoPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(height: 180)
                .cornerRadius(8)
            Image(systemName: "play.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
        }
    }


    private static func format(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MM-dd HH:mm"
        return df.string(from: date)
    }
}

private struct ResponsiveGrid: View {
    let width: CGFloat          // ← 直接用外部传入的可用宽
    let images: [String]
    let onTap: (Int) -> Void
    private let spacing: CGFloat = 6

    var body: some View {
        let cfg = layout(count: images.count, width: width, spacing: spacing)

        Group {
            if images.count == 1 {
                Image(images[0])
                    .resizable()
                    .scaledToFill()
                    .frame(width: cfg.singleSide, height: cfg.singleSide)
                    .clipped()
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                    .onTapGesture { onTap(0) }
            } else {
                VStack(alignment: .leading, spacing: spacing) {
                    ForEach(0..<cfg.rows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<cfg.columns, id: \.self) { col in
                                let idx = row * cfg.columns + col
                                if idx < images.count {
                                    Image(images[idx])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: cfg.cell, height: cfg.cell)
                                        .clipped()
                                        .cornerRadius(6)
                                        .contentShape(Rectangle())
                                        .onTapGesture { onTap(idx) }
                                } else {
                                    Color.clear.frame(width: cfg.cell, height: cfg.cell)
                                }
                            }
                        }
                    }
                }
                .frame(width: width, height: cfg.total) // ← 精确高度
            }
        }
    }

    private func layout(count: Int, width w: CGFloat, spacing: CGFloat)
      -> (columns: Int, rows: Int, cell: CGFloat, total: CGFloat, singleSide: CGFloat) {

        if count == 1 {
            let side = min(w, 300)
            return (1, 1, side, side, side)
        }
        let columns: Int = (count == 2 ? 2 : (count == 4 ? 2 : 3))
        let cell = floor((w - CGFloat(columns - 1) * spacing) / CGFloat(columns))
        let rows = Int(ceil(Double(count) / Double(columns)))
        let total = CGFloat(rows) * cell + CGFloat(rows - 1) * spacing
        return (columns, rows, cell, total, 0)
    }
}

