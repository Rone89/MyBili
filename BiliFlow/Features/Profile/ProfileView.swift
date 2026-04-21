import SwiftUI

struct ProfileView: View {
    var body: some View {
        List {
            Section("Current build") {
                Label("Home recommendations / popular feed", systemImage: "house.fill")
                Label("Suggestions / hot search / video search", systemImage: "magnifyingglass")
                Label("Video detail / related list", systemImage: "play.rectangle.fill")
                Label("Unsigned IPA from GitHub Actions", systemImage: "shippingbox.fill")
            }

            Section("Next milestones") {
                Label("Account login", systemImage: "person.badge.key.fill")
                Label("Like / favorite / coin", systemImage: "heart.fill")
                Label("History / watch later", systemImage: "clock.arrow.circlepath")
                Label("Native player page", systemImage: "video.fill")
            }

            Section("Notes") {
                Text("This first release focuses on the browsing flow so we can validate the API layer, UI shell, and release pipeline first.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Profile")
    }
}
