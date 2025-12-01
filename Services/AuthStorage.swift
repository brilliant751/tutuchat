import Foundation

final class AuthStorage {
    private let defaults: UserDefaults
    private let sessionKey = "auth.session"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ session: AuthSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: sessionKey)
    }

    func load() -> AuthSession? {
        guard let data = defaults.data(forKey: sessionKey) else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: sessionKey)
    }
}
