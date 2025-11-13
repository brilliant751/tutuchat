import Foundation
import Combine

@MainActor
final class ContactsViewModel: ObservableObject {
    @Published private(set) var shortcuts: [String] = [
        "新的朋友", "群聊", "标签", "公众号"
    ]
    @Published private(set) var contacts: [Contact] = []

    init() {
        contacts = [
            Contact(id: "u_a", name: "小明"),
            Contact(id: "u_b", name: "Alice"),
            Contact(id: "u_c", name: "张老师"),
            Contact(id: "u_d", name: "王同学")
        ].sorted { $0.name < $1.name }
    }
}
