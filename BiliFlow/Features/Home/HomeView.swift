import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var tabState: RootTabState
    @State private var viewModel = HomeViewModel()
    @Namespace private var detailTransition
    @State private var selectedVideoID: String?

    var body: some View {
        GeometryReader { proxy in
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

                content(availableSize: proxy.size)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: tabState.homeScrollRequest) { _, _ in
            if let firstID = viewModel.videos.first?.id {
                withAnimation(.easeInOut(duration: 0.28)) {
                    selectedVideoID = firstID
                }
            }
        }
        .onChange(of: viewModel.videos.map(\.id)) { _, ids in
            guard let current = selectedVideoID else {
                selectedVideoID = ids.first
                return
            }

            if !ids.contains(current) {
                selectedVideoID = ids.first
            }
        }
    }

    @ViewBuilder
    private func content(availableSize: CGSize) -> some View {
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
                VStack(alignment: .leading, spacing: 18) {
                    homeHeader
                        .padding(.horizontal, 16)

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
                        .padding(.horizontal, 16)
                    }

                    TabView(selection: Binding(
                        get: { selectedVideoID ?? videos.first?.id },
                        set: { selectedVideoID = $0 }
                    )) {
                        ForEach(videos) { video in
                            NavigationLink {
                                VideoDetailView(
                                    identifier: video.identifier,
                                    transitionID: video.id,
                                    transitionNamespace: detailTransition
                                )
                            } label: {
                                pagerCard(for: video, availableSize: availableSize)
                                    .matchedTransitionSource(id: video.id, in: detailTransition)
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMoreIfNeeded(current: video)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                            .tag(Optional(video.id))
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.top, 16)
                .refreshable {
                    await viewModel.refresh()
                }
                .animation(.easeInOut(duration: 0.22), value: viewModel.isRefreshing)
            }
        }
    }

    private var homeHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recommend")
                        .font(.system(size: 34, weight: .bold, design: .rounded))

                    Text("Swipe left and right to browse recommendations.")
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

    private func pagerCard(for video: VideoSummary, availableSize: CGSize) -> some View {
        let cardHeight = max(availableSize.height - 220, 380)

        return VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                AsyncCoverView(url: video.coverURL, height: min(cardHeight * 0.72, 520))

                Text(video.durationText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.72), in: Capsule())
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(video.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Text(video.authorName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label(video.viewText, systemImage: "play.fill")
                    Label(video.danmakuText, systemImage: "text.bubble.fill")
                    if let areaName = video.areaName, !areaName.isEmpty {
                        Label(areaName, systemImage: "tag.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                if viewModel.isLoadingMore, video.id == viewModel.videos.last?.id {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading more recommendations...")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.12))
        )
    }
}
