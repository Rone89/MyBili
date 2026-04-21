import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum Feed: String, CaseIterable, Identifiable {
        case recommend = "Recommend"
        case hot = "Popular"

        var id: String { rawValue }
    }

    var selectedFeed: Feed = .recommend
    var recommendState: Loadable<[VideoSummary]> = .idle
    var hotState: Loadable<[VideoSummary]> = .idle

    private let service: BiliService
    private var recommendCursor = 0
    private var hotPage = 1
    private var isLoadingMore = false

    init(service: BiliService = .shared) {
        self.service = service
    }

    var currentState: Loadable<[VideoSummary]> {
        switch selectedFeed {
        case .recommend:
            recommendState
        case .hot:
            hotState
        }
    }

    var currentVideos: [VideoSummary] {
        currentState.value ?? []
    }

    func loadSelectedIfNeeded() async {
        switch selectedFeed {
        case .recommend where !isLoadedOrLoading(recommendState):
            await reloadRecommend()
        case .hot where !isLoadedOrLoading(hotState):
            await reloadHot()
        default:
            break
        }
    }

    func refreshSelected() async {
        switch selectedFeed {
        case .recommend:
            await reloadRecommend()
        case .hot:
            await reloadHot()
        }
    }

    func loadMoreIfNeeded(current video: VideoSummary) async {
        guard !isLoadingMore, video.id == currentVideos.last?.id else {
            return
        }

        guard selectedFeed == .hot else {
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = hotPage + 1
            let nextItems = try await service.fetchHotVideos(page: nextPage)
            hotPage = nextPage
            let merged = uniqueVideos((hotState.value ?? []) + nextItems)
            hotState = .loaded(merged)
        } catch {
            if currentVideos.isEmpty {
                hotState = .failed(error.localizedDescription)
            }
        }
    }

    private func reloadRecommend() async {
        recommendState = .loading

        do {
            let items = try await service.fetchRecommendedVideos(refreshIndex: 0)
            recommendCursor = items.count
            recommendState = .loaded(uniqueVideos(items))
        } catch {
            recommendState = .failed(error.localizedDescription)
        }
    }

    private func reloadHot() async {
        hotState = .loading

        do {
            let items = try await service.fetchHotVideos(page: 1)
            hotPage = 1
            hotState = .loaded(uniqueVideos(items))
        } catch {
            hotState = .failed(error.localizedDescription)
        }
    }

    private func uniqueVideos(_ videos: [VideoSummary]) -> [VideoSummary] {
        var seen = Set<String>()
        return videos.filter { seen.insert($0.id).inserted }
    }

    private func isLoadedOrLoading(_ state: Loadable<[VideoSummary]>) -> Bool {
        switch state {
        case .loading, .loaded:
            return true
        case .idle, .failed:
            return false
        }
    }
}
