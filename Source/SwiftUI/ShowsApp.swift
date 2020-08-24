import SwiftUI

@main
struct ShowsApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            SubscriptionsView()
        }
    }
}
