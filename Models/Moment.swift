import Foundation

struct Moment: Identifiable, Decodable, Hashable {
    let id: String
    let userName: String
    let avatar: String?
    let text: String?
    let images: [String]?      // 资源名（Asset 名）
    let videoURL: String?      // 简化为文件名/URL 字符串
    let createdAt: Date
}
