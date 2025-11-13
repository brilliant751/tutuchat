import Foundation

struct User: Identifiable, Hashable {
    let id: String
    var nickname: String
    var avatarURL: URL? = nil
}
