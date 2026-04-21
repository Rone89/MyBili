import SwiftUI

struct HomeView: View {
    @Binding var selection: RootTabItem
    @State private var viewModel = HomeViewModel()
    @Namespace private var detailTransition

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
                let remainingVideos = feedVideos(from: videos)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        homeHeader
                        featuredGrid(videos: Array(videos.prefix(4)))
                        if !remainingVideos.isEmpty {
                            recommendSection(videos: remainingVideos)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
                .refreshable {
                    await viewModel.refresh()
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
                    selection = .profile
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
                selection = .search
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

    private func featuredGrid(videos: [VideoSummary]) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14),
        ]

        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(videos) { video in
                NavigationLink {
                    VideoDetailView(
                        identifier: video.identifier,
                        transitionID: video.id,
                        transitionNamespace: detailTransition
                    )
                } label: {
                    featuredTile(for: video)
                        .matchedTransitionSource(id: video.id, in: detailTransition)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func featuredTile(for video: VideoSummary) -> some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: video.coverURL, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.99, green: 0.76, blue: 0.48),
                                    Color(red: 0.47, green: 0.72, blue: 0.98),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            ProgressView()
                        }
                case .failure:
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.72, green: 0.78, blue: 0.98),
                                    Color(red: 0.95, green: 0.70, blue: 0.72),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                @unknown default:
                    Color(.secondarySystemFill)
                }
            }

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.16),
                    .black.opacity(0.45),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                if let areaName = video.areaName, !areaName.isEmpty {
                    Text(areaName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)
                }

                Text(video.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Label(video.viewText, systemImage: "play.fill")
                    Text(video.durationText)
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(14)
        }
        .frame(height: 164)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.38), lineWidth: 1)
        )
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
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func feedVideos(from videos: [VideoSummary]) -> [VideoSummary] {
        if videos.count > 4 {
            return Array(videos.dropFirst(4))
        }
        return []
    }
}
