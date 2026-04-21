import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var tabState: RootTabState
    @State private var viewModel = HomeViewModel()
    @Namespace private var detailTransition

    private let topAnchorID = "home-top-anchor"

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 0.81, green: 0.92, blue: 0.98),
                    Color(red: 0.96, green: 0.93, blue: 0.98),
                    Color(.systemGroupedBackground),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.recommendState {
        case .idle, .loading:
            LoadingStateView(
                title: "Loading videos",
                message: "The recommendation feed is loading."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .failed(message):
            ErrorStateView(
                title: "Recommend feed failed",
                message: message,
                actionTitle: "Retry"
            ) {
                Task {
                    await viewModel.refresh()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .loaded(videos):
            if videos.isEmpty {
                EmptyStateView(
                    title: "Nothing here yet",
                    message: "Try refreshing in a moment.",
                    systemImage: "tray"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            Color.clear
                                .frame(height: 1)
                                .id(topAnchorID)

                            homeHeader

                            if viewModel.isRefreshing {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Refreshing recommendations...")
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }

                            recommendSection(videos: videos)

                            if viewModel.isLoadingMore {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Loading more recommendations...")
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 28)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                    .animation(.easeInOut(duration: 0.22), value: viewModel.isRefreshing)
                    .onChange(of: tabState.homeScrollRequest) { _, _ in
                        withAnimation(.easeInOut(duration: 0.28)) {
                            proxy.scrollTo(topAnchorID, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private var homeHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recommend")
                        .font(.system(size: 34, weight: .bold, design: .rounded))

                    Text("Fresh videos picked from the recommendation feed.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    tabState.selected = .profile
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 46, height: 46)
                            .overlay {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 31))
                                    .foregroundStyle(Color(red: 0.22, green: 0.48, blue: 0.94))
                            }

                        Circle()
                            .fill(Color.red)
                            .frame(width: 18, height: 18)
                            .overlay {
                                Text("1")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                            .offset(x: 4, y: -2)
                    }
                }
                .buttonStyle(.plain)
            }

            Button {
                tabState.selected = .search
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    Text("Search videos, creators, topics")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.74))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func recommendSection(videos: [VideoSummary]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recommended videos")
                .font(.title3.bold())

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
    }
}
