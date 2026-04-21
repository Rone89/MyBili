import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    var suggestions: [SearchSuggestion] = []
    var discoveryState: Loadable<SearchDiscovery> = .idle
    var resultsState: Loadable<[VideoSummary]> = .idle
    var submittedQuery: String?

    private let service: BiliService
    private var currentPage = 1
    private var totalPages = 1
    private var isLoadingMore = false

    init(service: BiliService = .shared) {
        self.service = service
    }

    var isShowingResults: Bool {
        submittedQuery?.isEmpty == false
    }

    func loadDiscoveryIfNeeded() async {
        if case .idle = discoveryState {
            await reloadDiscovery()
        }
    }

    func reloadDiscovery() async {
        discoveryState = .loading

        do {
            discoveryState = .loaded(try await service.fetchSearchDiscovery())
        } catch {
            discoveryState = .failed(error.localizedDescription)
        }
    }

    func updateSuggestions() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }

        do {
            suggestions = try await service.fetchSearchSuggestions(term: trimmed)
        } catch {
            suggestions = []
        }
    }

    func useKeyword(_ keyword: String) {
        query = keyword
        suggestions = []
    }

    func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            submittedQuery = nil
            resultsState = .idle
            return
        }

        submittedQuery = trimmed
        resultsState = .loading
        currentPage = 1
        totalPages = 1
        suggestions = []

        do {
            let page = try await service.searchVideos(keyword: trimmed, page: 1)
            currentPage = page.currentPage
            totalPages = page.totalPages
            resultsState = .loaded(page.items)
        } catch {
            resultsState = .failed(error.localizedDescription)
        }
    }

    func refresh() async {
        if isShowingResults {
            await performSearch()
        } else {
            await reloadDiscovery()
        }
    }

    func loadMoreIfNeeded(current video: VideoSummary) async {
        guard let submittedQuery,
              isShowingResults,
              video.id == resultsState.value?.last?.id,
              currentPage < totalPages,
              !isLoadingMore else {
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let page = try await service.searchVideos(keyword: submittedQuery, page: nextPage)
            currentPage = page.currentPage
            totalPages = page.totalPages
            let merged = uniqueVideos((resultsState.value ?? []) + page.items)
            resultsState = .loaded(merged)
        } catch {
            if resultsState.value == nil {
                resultsState = .failed(error.localizedDescription)
            }
        }
    }

    private func uniqueVideos(_ videos: [VideoSummary]) -> [VideoSummary] {
        var seen = Set<String>()
        return videos.filter { seen.insert($0.id).inserted }
    }
}
