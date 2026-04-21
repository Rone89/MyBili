import SwiftUI

struct VideoCard: View {
    let video: VideoSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AsyncCoverView(url: video.coverURL, height: 204)

                Text(video.durationText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.72), in: Capsule())
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

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
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.15))
        )
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

