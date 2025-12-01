import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case server(statusCode: Int, message: String?)
    case decoding
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .server(_, let message):
            return message ?? "服务器错误"
        case .decoding:
            return "解析数据失败"
        case .network(let error):
            return error.localizedDescription
        }
    }
}

enum AuthAPI {
    private struct APIConfig {
        static let baseURL = URL(string: "http://47.114.86.161:12345")!
    }

    private struct LoginRequest: Encodable {
        let username: String
        let password: String
    }

    private struct RefreshRequest: Encodable {
        let token: String
    }

    private struct LoginResponse: Decodable {
        let token: String
        let userId: Int64
        let username: String
    }

    private struct ErrorBody: Decodable {
        let message: String?
        let error: String?
    }

    static func login(username: String, password: String) async throws -> AuthSession {
        let path = "/api/auth/login"
        let body = LoginRequest(username: username, password: password)
        let response: LoginResponse = try await performRequest(path: path, body: body)
        return AuthSession(token: response.token, userId: response.userId, username: response.username)
    }

    static func refresh(token: String) async throws -> AuthSession {
        let path = "/api/auth/refresh"
        let body = RefreshRequest(token: token)
        let response: LoginResponse = try await performRequest(path: path, body: body)
        return AuthSession(token: response.token, userId: response.userId, username: response.username)
    }

    // MARK: - Private

    private static func performRequest<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        body: RequestBody
    ) async throws -> ResponseBody {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.server(statusCode: -1, message: "无效的服务器响应")
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let errorBody = try? JSONDecoder().decode(ErrorBody.self, from: data)
            let serverMessage = errorBody?.message ?? errorBody?.error ?? String(data: data, encoding: .utf8)
            throw APIError.server(statusCode: httpResponse.statusCode, message: serverMessage)
        }

        do {
            return try JSONDecoder().decode(ResponseBody.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
