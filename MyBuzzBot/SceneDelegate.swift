import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        let storyboardName = UIDevice.current.userInterfaceIdiom == .pad ? "Ipad" : "Iphone"
        // Print the chosen storyboard name for debugging
        print("Loading storyboard: \(storyboardName)")
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = storyboard.instantiateInitialViewController() // Make sure the storyboard has an initial view controller
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}

