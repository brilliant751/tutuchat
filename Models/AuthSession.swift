import Foundation

struct AuthSession: Codable, Equatable {
    let token: String
    let userId: Int64
    let username: String
}
