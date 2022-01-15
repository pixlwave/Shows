import UIKit
import CloudKit

//@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()
        UserData.reloadSubscriptions()
        UserData.listenForChanges()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Notification received")
        
        guard
            let cloudNotification = CKNotification(fromRemoteNotificationDictionary: userInfo),
            cloudNotification.notificationType == .query,
            cloudNotification.title == "YouTubeChannel"
        else {
            completionHandler(.failed)
            return
        }
        
        UserData.reloadSubscriptions()
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Succeeded to register for remote notifications.")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
}

