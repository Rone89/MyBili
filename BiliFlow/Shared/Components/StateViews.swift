import SwiftUI

struct LoadingStateView: View {
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            VStack(spacing: 12) {
                ProgressView()
                Text(title)
                    .font(.headline)
            }
        } description: {
            Text(message)
        }
    }
}

struct ErrorStateView: View {
    let title: String
    let message: String
    let actionTitle: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button(actionTitle, action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }
}

