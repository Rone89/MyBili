import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Picker("Home feed", selection: $viewModel.selectedFeed) {
                ForEach(HomeViewModel.Feed.allCases) { feed in
                    Text(feed.rawValue).tag(feed)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            content
        }
        .navigationTitle("BiliFlow")
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.loadSelectedIfNeeded()
        }
        .onChange(of: viewModel.selectedFeed) { _, _ in
            Task {
                await viewModel.loadSelectedIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.currentState {
        case .idle, .loading:
            LoadingStateView(
                title: "Loading videos",
                message: "The home feed uses anonymous Bilibili endpoints."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .failed(message):
            ErrorStateView(
                title: "Home feed failed",
                message: message,
                actionTitle: "Retry"
            ) {
                Task {
                    await viewModel.refreshSelected()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .loaded(videos):
            if videos.isEmpty {
                EmptyStateView(
                    title: "Nothing here yet",
                    message: "Try refreshing in a moment or switch to another feed.",
                    systemImage: "tray"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .refreshable {
                    await viewModel.refreshSelected()
                }
            }
        }
    }
}
