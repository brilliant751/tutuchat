import SwiftUI

struct ImagePreviewView: View {
    let images: [String]          // 资源名数组（Assets 名称）
    @State var index: Int         // 起始索引
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(images.indices, id: \.self) { i in
                    ZoomableImage(name: images[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))

            // 顶部关闭
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
    }
}

private struct ZoomableImage: View {
    let name: String
    @State private var scale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .scaleEffect(scale)
                .gesture(MagnificationGesture().onChanged { scale = $0 }
                                         .onEnded { _ in withAnimation { scale = max(1, min(scale, 3)) }})
                .background(Color.black)
                .ignoresSafeArea()
        }
    }
}
