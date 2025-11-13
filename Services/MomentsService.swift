import Foundation

enum MomentsService {
    static func loadFromBundle() throws -> [Moment] {
        // 1) 找到包内 moments.json
        guard let url = Bundle.main.url(forResource: "moments", withExtension: "json") else {
            throw NSError(domain: "MomentsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "moments.json not found in bundle"])
        }
        // 2) 读取并解码
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let moments = try decoder.decode([Moment].self, from: data)
        // 3) 新到旧（朋友圈通常新内容在上）
        return moments.sorted { $0.createdAt > $1.createdAt }
    }
}
