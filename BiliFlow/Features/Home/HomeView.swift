import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Namespace private var detailTransition

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color(red: 0.22, green: 0.74, blue: 0.96).opacity(0.22),
                        Color(red: 0.96, green: 0.76, blue: 0.84).opacity(0.16),
                        Color(.systemGroupedBackground).opacity(0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: proxy.safeAreaInsets.top + 250)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .top)

                content(topInset: proxy.safeAreaInsets.top + 128)

                homeHeader(topInset: proxy.safeAreaInsets.top)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadSelectedIfNeeded()
        }
        .onChange(of: viewModel.selectedFeed) { _, _ in
            Task {
                await viewModel.loadSelectedIfNeeded()
            }
        }
    }

    private func homeHeader(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BiliFlow")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text("A cleaner native way to browse Bilibili.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Picker("Home feed", selection: $viewModel.selectedFeed) {
                ForEach(HomeViewModel.Feed.allCases) { feed in
                    Text(feed.rawValue).tag(feed)
                }
            }
            .pickerStyle(.segmented)
            .padding(6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.top, topInset + 12)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func content(topInset: CGFloat) -> some View {
        switch viewModel.currentState {
        case .idle, .loading:
            LoadingStateView(
                title: "Loading videos",
                message: "The home feed uses anonymous Bilibili endpoints."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, topInset)

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
            .padding(.top, topInset)

        case let .loaded(videos):
            if videos.isEmpty {
                EmptyStateView(
                    title: "Nothing here yet",
                    message: "Try refreshing in a moment or switch to another feed.",
                    systemImage: "tray"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, topInset)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 18) {
                        ForEach(videos) { video in
                            NavigationLink {
                                VideoDetailView(
                                    identifier: video.identifier,
                                    transitionID: video.id,
                                    transitionNamespace: detailTransition
                                )
                            } label: {
                                VideoCard(video: video)
                                    .matchedTransitionSource(id: video.id, in: detailTransition)
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMoreIfNeeded(current: video)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, topInset)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await viewModel.refreshSelected()
                }
            }
        }
    }
}
