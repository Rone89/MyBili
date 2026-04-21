import SwiftUI
import UIKit

struct VideoDetailView: View {
    @State private var viewModel: VideoDetailViewModel
    @State private var showingSafari = false
    @Environment(\.dismiss) private var dismiss

    private let transitionID: String?
    private let transitionNamespace: Namespace.ID?

    init(
        identifier: VideoIdentifier,
        transitionID: String? = nil,
        transitionNamespace: Namespace.ID? = nil
    ) {
        _viewModel = State(initialValue: VideoDetailViewModel(identifier: identifier))
        self.transitionID = transitionID
        self.transitionNamespace = transitionNamespace
    }

    @ViewBuilder
    var body: some View {
        if let transitionID, let transitionNamespace {
            detailScaffold
                .navigationTransition(.zoom(sourceID: transitionID, in: transitionNamespace))
        } else {
            detailScaffold
        }
    }

    private var detailScaffold: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color(red: 0.22, green: 0.74, blue: 0.96).opacity(0.22),
                        Color(red: 0.96, green: 0.76, blue: 0.84).opacity(0.18),
                        Color(.systemGroupedBackground).opacity(0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: proxy.safeAreaInsets.top + 280)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .top)

                content(
                    topInset: proxy.safeAreaInsets.top,
                    containerWidth: proxy.size.width
                )

                topBar(topInset: proxy.safeAreaInsets.top)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .background(
            NavigationChromeBridge(hideTabBar: true)
        )
        .sheet(isPresented: $showingSafari) {
            if let detail = viewModel.detailState.value, let url = detail.webURL {
                SafariSheet(url: url)
            }
        }
    }

    @ViewBuilder
    private func content(topInset: CGFloat, containerWidth: CGFloat) -> some View {
        switch viewModel.detailState {
        case .idle, .loading:
            LoadingStateView(
                title: "Loading video details",
                message: "Basic info and related videos are loading together."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, topInset + 64)

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, topInset + 64)

        case let .loaded(detail):
            let cardWidth = max(containerWidth - 24, 0)

            ScrollView(showsIndicators: false) {
                VStack(spacing: -34) {
                    heroCover(detail: detail, topInset: topInset, width: containerWidth)

                    VStack(alignment: .leading, spacing: 24) {
                        detailHeader(detail)
                        statsSection(detail)
                        descriptionSection(detail)
                        openInSafariButton
                        relatedSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 44)
                    .background(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.06), radius: 24, y: -8)
                    )
                    .frame(width: cardWidth, alignment: .leading)
                    .padding(.bottom, 24)
                }
                .frame(width: containerWidth)
            }
            .clipped()
            .ignoresSafeArea(edges: .top)
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

    private func detailHeader(_ detail: VideoDetail) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let areaName = detail.areaName, !areaName.isEmpty {
                Text(areaName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(red: 0.18, green: 0.53, blue: 0.86))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.18, green: 0.53, blue: 0.86).opacity(0.12))
                    )
            }

            Text(detail.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            ViewThatFits(in: .vertical) {
                HStack(spacing: 14) {
                    Label(detail.ownerName, systemImage: "person.fill")
                    Label(detail.viewText, systemImage: "play.fill")
                    Label(detail.danmakuText, systemImage: "text.bubble.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Label(detail.ownerName, systemImage: "person.fill")
                        .lineLimit(1)

                    HStack(spacing: 14) {
                        Label(detail.viewText, systemImage: "play.fill")
                        Label(detail.danmakuText, systemImage: "text.bubble.fill")
                    }
                    .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let publishedText = BiliFormatters.publishedText(detail.publishedAt) {
                Text("Published on \(publishedText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func descriptionSection(_ detail: VideoDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.title3.bold())

            Text(detail.descriptionText)
                .font(.body)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var openInSafariButton: some View {
        Button {
            showingSafari = true
        } label: {
            Label("Open in Safari", systemImage: "safari.fill")
                .frame(maxWidth: .infinity)
                .lineLimit(1)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(Color(red: 0.18, green: 0.53, blue: 0.86))
        .frame(maxWidth: .infinity)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func heroCover(detail: VideoDetail, topInset: CGFloat, width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: detail.coverURL, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    Rectangle()
                        .fill(Color(.secondarySystemFill))
                        .overlay {
                            ProgressView()
                        }
                case .failure:
                    Rectangle()
                        .fill(Color(.secondarySystemFill))
                        .overlay {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    Color(.secondarySystemFill)
                }
            }

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.08),
                    .black.opacity(0.42),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(detail.ownerName)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())

                HStack(spacing: 14) {
                    Label(detail.viewText, systemImage: "play.fill")
                    Label(detail.likeText, systemImage: "hand.thumbsup.fill")
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.bottom, 58)
        }
        .frame(width: width)
        .frame(height: topInset + 300)
        .clipShape(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
        )
    }

    private func topBar(topInset: CGFloat) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 42, height: 42)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, topInset + 10)
    }
}

private struct NavigationChromeBridge: UIViewControllerRepresentable {
    let hideTabBar: Bool

    func makeUIViewController(context: Context) -> Controller {
        Controller(hideTabBar: hideTabBar)
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {
        uiViewController.hideTabBar = hideTabBar
        uiViewController.applyChrome()
    }

    final class Controller: UIViewController {
        var hideTabBar: Bool

        init(hideTabBar: Bool) {
            self.hideTabBar = hideTabBar
            super.init(nibName: nil, bundle: nil)
            view.isHidden = true
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            applyChrome()
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            tabBarController?.tabBar.isHidden = false
        }

        func applyChrome() {
            tabBarController?.tabBar.isHidden = hideTabBar
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}
