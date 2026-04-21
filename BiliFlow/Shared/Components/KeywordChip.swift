import SwiftUI

struct KeywordChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(.tertiarySystemFill))
            )
    }
}

