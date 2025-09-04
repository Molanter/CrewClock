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
    private var apnsTokenWasSet = false

    // MARK: - App lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        viewModel = NotificationsViewModel()

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Ask permission, then register for APNs (device only path)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("🔐 Notification permission granted:", granted)
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        // 👉 Only try to fetch at launch on the SIMULATOR.
        // On a real device, FCM needs APNs first; we fetch after didRegisterForRemoteNotifications…
        #if targetEnvironment(simulator)
        fetchFCMToken(reason: "startup (simulator)")
        #endif

        print("GIDClientID:", Bundle.main.infoDictionary?["GIDClientID"] ?? "Not Found")
        return true
    }

    // MARK: - Helpers

    private func fetchFCMToken(reason: String, retryIfNil: Bool = false, attempt: Int = 1) {
        Messaging.messaging().token { token, error in
            if let token = token, !token.isEmpty {
                print("✅ FCM token (\(reason)):", token)
                self.viewModel.updateFcmToken(token: token)
            } else if let error = error {
                print("❌ Error fetching FCM token (\(reason)):", error.localizedDescription)
                // If device path complained about missing APNs, we’ll fetch again after APNs is set.
            } else if retryIfNil, attempt < 3 {
                let delay = 0.8 * Double(attempt)
                print("⏳ FCM token nil (\(reason)) — retrying in \(String(format: "%.1f", delay))s (attempt \(attempt+1)/3)")
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.fetchFCMToken(reason: reason, retryIfNil: retryIfNil, attempt: attempt + 1)
                }
            } else {
                print("⚠️ FCM token still nil (\(reason)).")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        completionHandler()
    }

    // Optional logging for background pushes
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let msgId = userInfo["gcm.message_id"] ?? userInfo["google.c.a.c_id"] ?? "nil"
        print("📬 didReceiveRemoteNotification gcm.message_id=\(msgId) userInfo=\(userInfo)")
        completionHandler(.noData)
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken, !token.isEmpty else {
            print("⚠️ didReceiveRegistrationToken with nil/empty token")
            return
        }
        print("🔁 didReceiveRegistrationToken:", token)
        viewModel.updateFcmToken(token: token)
    }

    // MARK: - APNs registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let apnsHex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📮 APNs device token:", apnsHex)

        Messaging.messaging().apnsToken = deviceToken
        apnsTokenWasSet = true

        // Now it’s safe to fetch FCM on devices.
        fetchFCMToken(reason: "post-APNs", retryIfNil: true)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications:", error.localizedDescription)
        // On device, we won’t have APNs so skip fetching here.
        // On simulator, we already attempted a startup fetch.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("➡️ Will enter foreground")
        // Optional: refresh token when app comes to foreground on devices (after APNs)
        #if !targetEnvironment(simulator)
        if apnsTokenWasSet {
            fetchFCMToken(reason: "foreground refresh", retryIfNil: true)
        }
        #endif
    }
}
