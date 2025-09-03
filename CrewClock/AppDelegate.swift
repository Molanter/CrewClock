//
//  AppDelegate.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/21/25.
//


import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    private var viewModel: NotificationsViewModel!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase first
        FirebaseApp.configure()

        // Init dependencies BEFORE any callbacks might use them
        viewModel = NotificationsViewModel()

        // Delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Ask for permission, then register for APNs (device-only)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("🔐 Notification permission granted:", granted)
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        print("GIDClientID:", Bundle.main.infoDictionary?["GIDClientID"] ?? "Not Found")
        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        completionHandler([.alert, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        completionHandler()
    }

    // MARK: - MessagingDelegate

    /// Called when FCM issues/refreshes a registration token.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken, !token.isEmpty else {
            print("⚠️ didReceiveRegistrationToken with nil/empty token")
            return
        }
        #if targetEnvironment(simulator)
        print("🧪 Simulator token ignored: \(token)")
        return
        #endif
        print("⬆️ Uploading FCM token to backend:", token)   // <-- verify this prints a *FCM* token
        viewModel.updateFcmToken(token: token)
    }

    // MARK: - APNs registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let apnsHex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📮 APNs device token:", apnsHex)

        // Hand APNs token to Firebase
        Messaging.messaging().apnsToken = deviceToken

        // On simulator there is no real APNs path → skip fetching FCM token
        #if targetEnvironment(simulator)
        print("🧪 Simulator detected: skipping FCM token fetch (no real APNs).")
        return
        #endif

        // Now it's safe to fetch the FCM token (APNs token is set)
        Messaging.messaging().token { token, error in
            if let token = token {
                print("✅ Fetched FCM token:", token)
                self.viewModel.updateFcmToken(token: token)
            } else {
                print("❌ Error fetching FCM registration token:", error?.localizedDescription ?? "unknown")
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications:", error.localizedDescription)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("➡️ Will enter foreground")
    }
}
