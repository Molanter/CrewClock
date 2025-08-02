//
//  NotificationsViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/21/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class NotificationsViewModel: ObservableObject {
    private var auth = Auth.auth()
    private var db = Firestore.firestore()

    @Published var tokensArray = [String]()
    @Published var notifications: [NotificationFB] = []
    
    func updateFcmToken(token: String){
        guard let userId = auth.currentUser?.uid else { return }
        let ref = db.collection("users").document(userId).collection("fcmTokens").document(token)
        
        ref.setData([:]) { error in
            if let error = error {
                print("Error while updating FCM token: \(error)")
            } else {
                app.fcmToken = token
                print("✅ FCM token updated!")
            }
        }
    }
    
    func deleteFcmToken(userId: String, token: String) {
        let ref = db.collection("users").document(userId)
            .collection("fcmTokens").document(token)

        ref.delete { err in
            if let err = err {
                print("Error removing FCM token: \(err)")
            } else {
                print("✅ FCM token removed: \(token)")
            }
        }
    }
    
    //MARK: Notification
    
    /// Fetches FCM tokens by user UID and sends notification
    func getFcmByUid(uid: String, notification: NotificationModel) {
        db.collection("users")
            .document(uid)
            .getDocument { [weak self] documentSnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching user token: \(error.localizedDescription)")
                    return
                }

                guard let data = documentSnapshot?.data() else {
                    print("No user document found for UID: \(uid)")
                    return
                }

                let token = data["token"] as? String ?? ""
                print("Token:", token)
                // recipientUID is [String], so wrap uid as an array
                let updatedNotification = NotificationModel(
                    notificationId: notification.notificationId,
                    title: notification.title,
                    message: notification.message,
                    timestamp: notification.timestamp,
                    recipientUID: [uid],
                    fromUID: notification.fromUID,
                    isRead: notification.isRead,
                    status: notification.status,
                    type: notification.type,
                    relatedId: notification.relatedId,
                    imageUrl: notification.imageUrl
                )
                self.sendNotification(updatedNotification)
            }
    }
    
    
    func sendNotification(_ notification: NotificationModel) {
        for recipientUID in notification.recipientUID {
            db.collection("users")
                .document(recipientUID)
                .collection("fcmTokens")
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }

                    if let error = error {
                        print("Error fetching FCM tokens for \(recipientUID): \(error.localizedDescription)")
                        return
                    }

                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("❌ No FCM tokens found for user: \(recipientUID)")
                        return
                    }

                    let tokens = documents.map { $0.documentID }

                    for token in tokens {
                        var notificationData: [String: Any] = [
                            "notificationId": notification.notificationId,
                            "title": notification.title,
                            "message": notification.message,
                            "timestamp": Timestamp(date: notification.timestamp),
                            "recipientUID": [recipientUID],
                            "isRead": notification.isRead,
                            "status": notification.status.rawValue,
                            "type": notification.type.rawValue,
                            "relatedId": notification.relatedId,
                            "fromUID": notification.fromUID
                        ]
                        
                        // Only add imageUrl if it's a valid URL string starting with "http"
                        if let imageUrl = notification.imageUrl, imageUrl.starts(with: "http") {
                            notificationData["imageUrl"] = imageUrl
                        }

                        Firestore.firestore()
                            .collection("notifications")
                            .document("\(notification.notificationId)_\(recipientUID)")
                            .setData(notificationData) { error in
                                if let error = error {
                                    print("❌ Error saving notification for \(recipientUID): \(error.localizedDescription)")
                                } else {
                                    print("✅ Notification saved to Firestore for \(recipientUID)")
                                    self.sendNotificationViaFunction(notification)
                                }
                            }
                    }
                }
        }
    }
    
    private func sendNotificationViaFunction(_ notification: NotificationModel) {
        guard let url = URL(string: "https://us-central1-curchnote.cloudfunctions.net/sendNotification") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "title": notification.title,
            "message": notification.message,
            "recipientUIDs": notification.recipientUID,
            "fromUID": notification.fromUID,
            "type": notification.type.rawValue,
            "relatedId": notification.relatedId,
            "notificationId": notification.notificationId
        ]

        // Only add imageUrl if it is a valid URL string
        if let imageUrl = notification.imageUrl,
            !imageUrl.isEmpty,
            imageUrl is String,
            imageUrl.starts(with: "http") {
            body["imageUrl"] = imageUrl
        }

        print("📦 Sending push payload:", body)

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("❌ Failed to serialize notification payload: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error calling push function: \(error.localizedDescription)")
            } else {
                print("✅ Push function called")
            }
        }.resume()
    }
    
//    private func sendPushNotification(to token: String, title: String, body: String) {
//        let message: [String: Any] = [
//            "to": token,
//            "notification": [
//                "title": title,
//                "subtitle": "",
//                "body": body,
//                "image": "",
//                "badge": 1
//            ],
//            "data": [
//                "sound": "default",
//                "link": ""
//            ]
//        ]
//
//        guard let url = URL(string: "https://fcm.googleapis.com/fcm/send") else { return }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("key=your_key", forHTTPHeaderField: "Authorization") // Replace with actual server key
//
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
//            request.httpBody = jsonData
//
//            URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    print("❌ Error sending push notification: \(error.localizedDescription)")
//                } else if let data = data {
//                    let responseString = String(data: data, encoding: .utf8)
//                    print("✅ Push notification sent: \(responseString ?? "")")
//                }
//            }.resume()
//        } catch {
//            print("❌ Error serializing JSON for push notification: \(error.localizedDescription)")
//        }
//    }

//    /// Triggers a push notification to a user by UID
//    func triggerPushNotification(toUID uid: String, title: String, body: String) {
//        db.collection("users")
//            .document(uid)
//            .getDocument { [weak self] snapshot, error in
//                guard let self = self else { return }
//
//                if let error = error {
//                    print("❌ Error fetching user document: \(error.localizedDescription)")
//                    return
//                }
//
//                guard let data = snapshot?.data(),
//                      let token = data["token"] as? String, !token.isEmpty else {
//                    print("❌ No FCM token found for user: \(uid)")
//                    return
//                }
//
//                self.sendPushNotification(to: token, title: title, body: body)
//            }
//    }
//
//    func sendNotification() {
//        guard let url = URL(string: "https://us-central1-curchnote.cloudfunctions.net/updateBadgeCount") else {
//            print("Invalid Cloud Function URL")
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let body: [String: Any] = [
//            "userId": auth.currentUser?.uid ?? "",
//            "badgeCount": 5
//        ]
//
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: body)
//        } catch {
//            print("Error encoding JSON: \(error)")
//            return
//        }
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error sending notification: \(error)")
//                return
//            }
//
//            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
//                print("Notification sent successfully")
//            } else {
//                print("Error sending notification. Response: \(response.debugDescription)")
//            }
//        }.resume()
//    }
    
    /// Fetch notifications where recipientUID contains the given uid
    func fetchNotifications(completion: @escaping ([NotificationFB]) -> Void) {
        guard let uid = auth.currentUser?.uid else {return}
        
        db.collection("notifications")
            .whereField("recipientUID", arrayContains: uid)
            .order(by: "timestamp", descending: true)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    completion([])
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let notifications = documents.map { doc in
                    NotificationFB(data: doc.data(), documentId: doc.documentID)
                }
                self.notifications = notifications
                completion(notifications)
                
                print("✅ Notifications fetched succesfully :-:")
            }
    }
    
    /// Updates a notification's status by its notificationId
    func updateNotificationStatus(notificationId: String, newStatus: NotificationStatus, completion: ((Bool) -> Void)? = nil) {
        let ref = db.collection("notifications").document(notificationId)
        ref.updateData(["status": newStatus.rawValue]) { [weak self] error in
            if let error = error {
                print("Error updating notification status: \(error.localizedDescription)")
                completion?(false)
            } else {
                if let index = self?.notifications.firstIndex(where: { $0.notificationId == notificationId }) {
                    self?.notifications[index].status = newStatus
                }
                print("Notification status updated successfully!")
                completion?(true)
            }
        }
    }
    
}
