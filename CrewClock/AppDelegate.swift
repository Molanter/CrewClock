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
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()

      Messaging.messaging().delegate = self
      UserNotifications.UNUserNotificationCenter.current().delegate = self
      
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
          if granted {
              print("Notification permission granted: \(granted)")
              DispatchQueue.main.async {
                  UIApplication.shared.registerForRemoteNotifications()
              }
          }
      }

      viewModel = NotificationsViewModel()
      
      print("GIDClientID: \(Bundle.main.infoDictionary?["GIDClientID"] ?? "Not Found")")
    return true
  }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle notification, if needed

        // Increment the current badge count by 1
        UIApplication.shared.applicationIconBadgeNumber = 0

        // Customize the presentation options (e.g., show alert and play sound)
        let presentationOptions: UNNotificationPresentationOptions = [.alert, .sound]
        completionHandler(presentationOptions)
    }
        // Handle remote notification received when app is in the background or terminated
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification, if needed
        completionHandler()

        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Increment badge count by 1
//        if let aps = response.notification.request.content.userInfo["aps"] as? [String: Any],
//               let badgeCount = aps["badge"] as? Int {
//                // Update badge count
//                UIApplication.shared.applicationIconBadgeNumber = badgeCount
//            }
    }
    
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcm = Messaging.messaging().fcmToken {
            print("🚨 FCM Token:", fcm)
            viewModel.updateFcmToken(token: fcm)
//            app.fcmToken = fcm
        }
    }
    
    
    // Handle device token registration for remote notifications
       func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
           let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
           print("Device Token: \(token)")
           Messaging.messaging().apnsToken = deviceToken
           // Send the device token to your server for further handling
           Messaging.messaging().token { token, error in
               if let error = error {
                   print("Error fetching FCM registration token: \(error)")
               } else if let token = token {
                   print("FCM Token: \(token)")
                   self.viewModel.updateFcmToken(token: token)
               }
           }
       }
       
       func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
           print("Failed to register for remote notifications: \(error.localizedDescription)")
       }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        UserDefaults(suiteName: "group.com.yourApp.bundleId")?.set(1, forKey: "count")
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("foregraund           ")
    }

}
