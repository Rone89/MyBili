import SwiftUI

struct VideoDetailView: View {
    @State private var viewModel: VideoDetailViewModel
    @State private var showingSafari = false

    init(identifier: VideoIdentifier) {
        _viewModel = State(initialValue: VideoDetailViewModel(identifier: identifier))
    }

    var body: some View {
        Group {
            switch viewModel.detailState {
            case .idle, .loading:
                LoadingStateView(
                    title: "Loading video details",
                    message: "Basic info and related videos are loading together."
                )

            case let .failed(message):
            ErrorStateView(
                    title: "Detail page failed",
                    message: message,
                    actionTitle: "Retry"
                ) {
                    Task {
                        await viewModel.refresh()
                    }
                }

            case let .loaded(detail):
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        AsyncCoverView(url: detail.coverURL, height: 240)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(detail.title)
                                .font(.title2.bold())

                            HStack(spacing: 12) {
                                Label(detail.ownerName, systemImage: "person.fill")
                                Label(detail.viewText, systemImage: "play.fill")
                                Label(detail.danmakuText, systemImage: "text.bubble.fill")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                            if let publishedText = BiliFormatters.publishedText(detail.publishedAt) {
                                Text("Published on \(publishedText)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            if let areaName = detail.areaName, !areaName.isEmpty {
                                Text(areaName)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.pink)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.pink.opacity(0.12), in: Capsule())
                            }
                        }

                        statsSection(detail)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Description")
                                .font(.title3.bold())

                            Text(detail.descriptionText)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                        }

                        Button {
                            showingSafari = true
                        } label: {
                            Label("Open the playback page in Safari", systemImage: "safari.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        relatedSection
                    }
                    .padding()
                }
                .sheet(isPresented: $showingSafari) {
                    if let url = detail.webURL {
                        SafariSheet(url: url)
                    }
                }
            }
        }
        .navigationTitle("Video")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private func statsSection(_ detail: VideoDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.title3.bold())

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                spacing: 12
            ) {
                statCell(title: "Likes", value: detail.likeText, systemImage: "hand.thumbsup.fill")
                statCell(title: "Coins", value: detail.coinText, systemImage: "circle.hexagongrid.fill")
                statCell(title: "Favorites", value: detail.favoriteText, systemImage: "star.fill")
                statCell(title: "Shares", value: detail.shareText, systemImage: "square.and.arrow.up.fill")
                statCell(title: "Duration", value: detail.durationText, systemImage: "clock.fill")
                statCell(title: "Danmaku", value: detail.danmakuText, systemImage: "text.bubble.fill")
            }
        }
    }

    private func statCell(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private var relatedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related videos")
                .font(.title3.bold())

            switch viewModel.relatedState {
            case .idle, .loading:
                ProgressView("Loading related videos")
                    .frame(maxWidth: .infinity, alignment: .leading)

            case let .failed(message):
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

            case let .loaded(videos):
                if videos.isEmpty {
                    Text("No related videos are available right now.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(videos) { video in
                        NavigationLink {
                            VideoDetailView(identifier: video.identifier)
                        } label: {
                            VideoCard(video: video)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
