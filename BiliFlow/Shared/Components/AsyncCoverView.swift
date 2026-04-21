import SwiftUI

struct AsyncCoverView: View {
    let url: URL?
    let height: CGFloat

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                fallback
            case .empty:
                ZStack {
                    fallback
                    ProgressView()
                }
            @unknown default:
                fallback
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var fallback: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(.secondarySystemFill))
            .overlay {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
    }
}

