import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var recommendState: Loadable<[VideoSummary]> = .idle

    private let service: BiliService

    init(service: BiliService = .shared) {
        self.service = service
    }

    var videos: [VideoSummary] {
        recommendState.value ?? []
    }

    func loadIfNeeded() async {
        switch recommendState {
        case .loading, .loaded:
            return
        case .idle, .failed:
            await reloadRecommend()
        }
    }

    func refresh() async {
        await reloadRecommend()
    }

    private func reloadRecommend() async {
        recommendState = .loading

        do {
            let items = try await service.fetchRecommendedVideos(refreshIndex: 0)
            recommendState = .loaded(uniqueVideos(items))
        } catch {
            recommendState = .failed(error.localizedDescription)
        }
    }

    private func uniqueVideos(_ videos: [VideoSummary]) -> [VideoSummary] {
        var seen = Set<String>()
        return videos.filter { seen.insert($0.id).inserted }
    }
}
