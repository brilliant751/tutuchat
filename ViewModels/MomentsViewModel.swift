import Foundation
import Combine

@MainActor
final class MomentsViewModel: ObservableObject {
    @Published private(set) var moments: [Moment] = []
    @Published private(set) var errorText: String?

    init() {
        load()
    }

    func load() {
        do {
            moments = try MomentsService.loadFromBundle()
            errorText = nil
        } catch {
            errorText = error.localizedDescription
        }
    }
}
