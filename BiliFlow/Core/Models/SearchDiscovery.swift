import Foundation

struct SearchDiscovery: Hashable, Sendable {
    let defaultKeyword: String?
    let hotKeywords: [SearchHotKeyword]
}

struct SearchHotKeyword: Identifiable, Hashable, Sendable {
    let id: Int
    let text: String
}

struct SearchSuggestion: Identifiable, Hashable, Sendable {
    let text: String

    var id: String { text }
}

struct SearchResultPage: Hashable, Sendable {
    let items: [VideoSummary]
    let currentPage: Int
    let totalPages: Int

    var hasMore: Bool {
        currentPage < totalPages
    }
}

