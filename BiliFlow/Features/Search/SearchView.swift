import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 12),
    ]

    var body: some View {
        Group {
            if viewModel.isShowingResults {
                resultsContent
            } else {
                discoveryContent
            }
        }
        .navigationTitle("Search")
        .searchable(text: $viewModel.query, prompt: "Search videos, keywords, creators")
        .searchSuggestions {
            ForEach(viewModel.suggestions) { suggestion in
                Button {
                    viewModel.useKeyword(suggestion.text)
                    Task {
                        await viewModel.performSearch()
                    }
                } label: {
                    Text(suggestion.text)
                }
            }
        }
        .onSubmit(of: .search) {
            Task {
                await viewModel.performSearch()
            }
        }
        .task {
            await viewModel.loadDiscoveryIfNeeded()
        }
        .task(id: viewModel.query) {
            await viewModel.updateSuggestions()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private var discoveryContent: some View {
        switch viewModel.discoveryState {
        case .idle, .loading:
            LoadingStateView(
                title: "Preparing search",
                message: "Loading the default keyword and current hot searches."
            )

        case let .failed(message):
            ErrorStateView(
                title: "Search page failed",
                message: message,
                actionTitle: "Retry"
            ) {
                Task {
                    await viewModel.reloadDiscovery()
                }
            }

        case let .loaded(discovery):
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let defaultKeyword = discovery.defaultKeyword, !defaultKeyword.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested search")
                                .font(.title3.bold())

                            Button {
                                viewModel.useKeyword(defaultKeyword)
                                Task {
                                    await viewModel.performSearch()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text(defaultKeyword)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color(.secondarySystemBackground))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hot searches")
                            .font(.title3.bold())

                        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                            ForEach(discovery.hotKeywords) { keyword in
                                Button {
                                    viewModel.useKeyword(keyword.text)
                                    Task {
                                        await viewModel.performSearch()
                                    }
                                } label: {
                                    KeywordChip(title: keyword.text)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private var resultsContent: some View {
        switch viewModel.resultsState {
        case .idle, .loading:
            LoadingStateView(
                title: "Searching",
                message: "Video results will be loaded page by page."
            )

        case let .failed(message):
            ErrorStateView(
                title: "Search failed",
                message: message,
                actionTitle: "Retry"
            ) {
                Task {
                    await viewModel.performSearch()
                }
            }

        case let .loaded(videos):
            if videos.isEmpty {
                EmptyStateView(
                    title: "No results found",
                    message: "Try a different keyword.",
                    systemImage: "magnifyingglass"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 18) {
                        ForEach(videos) { video in
                            NavigationLink {
                                VideoDetailView(identifier: video.identifier)
                            } label: {
                                VideoCard(video: video)
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMoreIfNeeded(current: video)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
