import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""

    @Published private(set) var session: AuthSession?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let storage = AuthStorage()

    var isSignedIn: Bool {
        session != nil
    }

    init() {
        if let savedSession = storage.load() {
            session = savedSession
            username = savedSession.username
        }
    }

    func login() async {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty else {
            errorMessage = "请输入账号"
            return
        }
        guard !password.isEmpty else {
            errorMessage = "请输入密码"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let session = try await AuthAPI.login(username: trimmedUsername, password: password)
            self.session = session
            storage.save(session)
            password = ""
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func logout() {
        storage.clear()
        session = nil
        password = ""
        errorMessage = nil
    }

    func refreshTokenIfNeeded() async {
        guard let current = session else { return }
        do {
            let refreshed = try await AuthAPI.refresh(token: current.token)
            session = refreshed
            storage.save(refreshed)
        } catch {
            // 刷新失败时保持原状态，交由下次手动登录
        }
    }
}
