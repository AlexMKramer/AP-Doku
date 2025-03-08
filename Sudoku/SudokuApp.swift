import SwiftUI
import UserNotifications

@main
struct SudokuApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var connectionManager = ArchipelagoConnectionManager.shared
    
    // Create a notification delegate instance.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .onChange(of: scenePhase) { newPhase, _ in
            if newPhase == .active {
                // When the app becomes active, attempt a reconnect if needed.
                if connectionManager.shouldAutoReconnect {
                    if connectionManager.client == nil || connectionManager.client!.isOpen == false {
                        connectionManager.attemptReconnect()
                    } else if connectionManager.client!.isOpen == true {
                        print("Already connected!")
                    }

                }
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self  // Set the delegate
        return true
    }
    
    // This method is called when a notification is delivered while the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Present the notification as a banner and play sound
        completionHandler([.banner, .sound])
    }
}
