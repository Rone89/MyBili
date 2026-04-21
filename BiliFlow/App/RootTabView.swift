import SwiftUI
import UIKit

enum RootTabItem: Int, Hashable {
    case home = 0
    case search = 1
    case profile = 2
}

final class RootTabState: ObservableObject {
    @Published var selected: RootTabItem = .home
    @Published var homeScrollRequest: Int = 0

    func requestHomeScrollToTop() {
        homeScrollRequest += 1
    }
}

struct RootTabView: View {
    @StateObject private var tabState = RootTabState()

    var body: some View {
        RootTabBarController(tabState: tabState)
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

private struct RootTabBarController: UIViewControllerRepresentable {
    @ObservedObject var tabState: RootTabState

    func makeCoordinator() -> Coordinator {
        Coordinator(tabState: tabState)
    }

    func makeUIViewController(context: Context) -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.delegate = context.coordinator
        tabBarController.view.backgroundColor = .clear
        tabBarController.tabBar.isTranslucent = true

        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = .clear
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance

        tabBarController.viewControllers = makeViewControllers()
        tabBarController.selectedIndex = tabState.selected.rawValue
        context.coordinator.hasCompletedInitialSelection = true
        return tabBarController
    }

    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
        if uiViewController.selectedIndex != tabState.selected.rawValue {
            uiViewController.selectedIndex = tabState.selected.rawValue
        }
    }

    private func makeViewControllers() -> [UIViewController] {
        let home = UIHostingController(
            rootView: NavigationStack {
                HomeView()
                    .environmentObject(tabState)
            }
        )
        home.view.backgroundColor = .clear
        home.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let search = UIHostingController(
            rootView: NavigationStack {
                SearchView()
                    .environmentObject(tabState)
            }
        )
        search.view.backgroundColor = .clear
        search.tabBarItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )

        let profile = UIHostingController(
            rootView: NavigationStack {
                ProfileView()
                    .environmentObject(tabState)
            }
        )
        profile.view.backgroundColor = .clear
        profile.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )

        return [home, search, profile]
    }

    final class Coordinator: NSObject, UITabBarControllerDelegate {
        private let tabState: RootTabState
        var hasCompletedInitialSelection = false

        init(tabState: RootTabState) {
            self.tabState = tabState
        }

        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            guard hasCompletedInitialSelection,
                  let viewControllers = tabBarController.viewControllers,
                  let index = viewControllers.firstIndex(of: viewController),
                  let selected = RootTabItem(rawValue: index) else {
                return
            }

            if tabState.selected == selected {
                if selected == .home {
                    tabState.requestHomeScrollToTop()
                }
            } else {
                tabState.selected = selected
            }
        }
    }
}
