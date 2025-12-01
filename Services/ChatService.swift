import Foundation

struct ChatSummaryResponse: Decodable {
    let chatId: Int64
    let title: String?
    let lastMessageContent: String?
    let lastMessageTimestamp: Int64?
    let unreadCount: Int64
}

struct MessageResponse: Decodable {
    let id: Int64
    let chatId: Int64
    let senderId: Int64
    let content: String
    let createdAt: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        chatId = try container.decode(Int64.self, forKey: .chatId)
        senderId = try container.decode(Int64.self, forKey: .senderId)
        content = try container.decode(String.self, forKey: .content)

        // createdAt 可能是 ISO8601 字符串，也可能是毫秒时间戳，做兼容解析
        if let millis = try? container.decode(Int64.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: TimeInterval(millis) / 1000)
        } else if let isoString = try? container.decode(String.self, forKey: .createdAt),
                  let date = ISO8601DateFormatter().date(from: isoString) {
            createdAt = date
        } else {
            createdAt = Date()
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, chatId, senderId, content, createdAt
    }
}

private struct PageResponse<T: Decodable>: Decodable {
    let content: [T]
}

enum ChatService {
    private struct APIConfig {
        static let baseURL = URL(string: "http://47.114.86.161:12345")!
    }

    static func fetchMyChats(token: String) async throws -> [ChatSummaryResponse] {
        let path = "/api/me/chats"
        return try await get(path: path, token: token)
    }

    static func fetchMessages(chatId: Int64, token: String?, page: Int = 0, size: Int = 100) async throws -> [MessageResponse] {
        var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent("/api/chats/\(chatId)/messages"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            .init(name: "page", value: "\(page)"),
            .init(name: "size", value: "\(size)")
        ]
        guard let url = components?.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        if let token { request.setValue(token, forHTTPHeaderField: "X-Auth-Token") }
        let pageResponse: PageResponse<MessageResponse> = try await perform(request: request)
        return pageResponse.content
    }

    static func markChatRead(chatId: Int64, lastReadMessageId: Int64?, token: String) async throws {
        let path = "/api/chats/\(chatId)/read"
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        if let lastReadMessageId {
            request.httpBody = try JSONEncoder().encode(["lastReadMessageId": lastReadMessageId])
        }

        _ = try await perform(request: request) as EmptyResponse
    }

    // MARK: - Private helpers

    private static func get<T: Decodable>(path: String, token: String) async throws -> T {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        return try await perform(request: request)
    }

    private static func perform<T: Decodable>(request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.server(statusCode: -1, message: "无效的服务器响应")
        }

        guard 200..<300 ~= http.statusCode else {
            let body = try? JSONDecoder().decode(ErrorBody.self, from: data)
            let serverMessage = body?.message ?? body?.error ?? String(data: data, encoding: .utf8)
            throw APIError.server(statusCode: http.statusCode, message: serverMessage)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private struct ErrorBody: Decodable {
        let message: String?
        let error: String?
    }

    private struct EmptyResponse: Decodable {}
}
