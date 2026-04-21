import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class HomeViewModel {
    var recommendState: Loadable<[VideoSummary]> = .idle
    var isRefreshing = false
    var isLoadingMore = false

    private let service: BiliService
    private var recommendCursor = 0

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
            await reloadRecommend(showLoading: true)
        }
    }

    func refresh() async {
        await reloadRecommend(showLoading: false)
    }

    func loadMoreIfNeeded(current video: VideoSummary) async {
        guard !isLoadingMore,
              !isRefreshing,
              video.id == videos.last?.id,
              !videos.isEmpty else {
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let incoming = try await service.fetchRecommendedVideos(refreshIndex: recommendCursor)
            guard !incoming.isEmpty else {
                return
            }

            let merged = uniqueVideos(videos + incoming)
            recommendCursor += incoming.count

            withAnimation(.easeInOut(duration: 0.25)) {
                recommendState = .loaded(merged)
            }
        } catch {
            return
        }
    }

    private func reloadRecommend(showLoading: Bool) async {
        if showLoading || recommendState.value == nil {
            recommendState = .loading
        } else {
            isRefreshing = true
        }

        defer {
            isRefreshing = false
        }

        do {
            let items = try await service.fetchRecommendedVideos(refreshIndex: 0)
            let unique = uniqueVideos(items)
            recommendCursor = unique.count

            withAnimation(.easeInOut(duration: 0.25)) {
                recommendState = .loaded(unique)
            }
        } catch {
            if recommendState.value == nil {
                recommendState = .failed(error.localizedDescription)
            }
        }
    }

    private func uniqueVideos(_ videos: [VideoSummary]) -> [VideoSummary] {
        var seen = Set<String>()
        return videos.filter { seen.insert($0.id).inserted }
    }
}
