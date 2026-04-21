import Foundation
import Observation

@MainActor
@Observable
final class VideoDetailViewModel {
    var detailState: Loadable<VideoDetail> = .idle
    var relatedState: Loadable<[VideoSummary]> = .idle

    let identifier: VideoIdentifier

    private let service: BiliService

    init(identifier: VideoIdentifier, service: BiliService = .shared) {
        self.identifier = identifier
        self.service = service
    }

    func loadIfNeeded() async {
        if case .idle = detailState {
            await refresh()
        }
    }

    func refresh() async {
        detailState = .loading

        do {
            let detail = try await service.fetchVideoDetail(identifier: identifier)
            detailState = .loaded(detail)
            relatedState = .loading

            do {
                let related = try await service.fetchRelatedVideos(bvid: detail.bvid)
                relatedState = .loaded(related)
            } catch {
                relatedState = .failed(error.localizedDescription)
            }
        } catch {
            detailState = .failed(error.localizedDescription)
        }
    }
}

