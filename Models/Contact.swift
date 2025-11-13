import Foundation

struct Contact: Identifiable, Hashable {
    let id: String
    var name: String
    var avatar: String? = nil // 先用首字母做占位，后续可换 URL
}
