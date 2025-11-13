import Foundation
import Combine

@MainActor
final class MeViewModel: ObservableObject {
    struct MenuItem: Identifiable, Hashable {
        let id = UUID()
        let sfSymbol: String
        let title: String
        let dest: Dest
        enum Dest: Hashable { case album, pay, settings, about }
    }

    @Published private(set) var nickname = "孙凯文"
    @Published private(set) var wechatId = "tutu_skw"

    @Published private(set) var menus: [MenuItem] = [
        .init(sfSymbol: "photo.on.rectangle", title: "相册",   dest: .album),
        .init(sfSymbol: "creditcard",         title: "支付",   dest: .pay),
        .init(sfSymbol: "gearshape",          title: "设置",   dest: .settings),
        .init(sfSymbol: "info.circle",        title: "关于",   dest: .about)
    ]
}
