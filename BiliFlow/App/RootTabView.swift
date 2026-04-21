import SwiftUI

enum RootTabItem: Hashable {
    case home
    case search
    case profile
}

struct RootTabView: View {
    @State private var selection: RootTabItem = .home

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                HomeView(selection: $selection)
            }
            .tag(RootTabItem.home)
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                SearchView()
            }
            .tag(RootTabItem.search)
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            NavigationStack {
                ProfileView()
            }
            .tag(RootTabItem.profile)
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
    }
}
