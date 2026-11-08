import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    /// The single source of truth for the whole app. Every controller gets this
    /// same instance through its initializer.
    let store = StudentStore()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let list = StudentListViewController(store: store, mode: .all)
        window.rootViewController = UINavigationController(rootViewController: list)
        window.makeKeyAndVisible()
        self.window = window
    }
}
