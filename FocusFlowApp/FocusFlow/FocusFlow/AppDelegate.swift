import UIKit
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // If FirebaseApp is already configured elsewhere, do not double-configure.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        return true
    }
}
