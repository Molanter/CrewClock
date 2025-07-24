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
    
    func updateFcmToken(token: String){
        guard let userId = auth.currentUser?.uid else{return}
        let ref = db.collection("users").document(userId).collection("fcmTokens").document(token)
        
        ref.setData(
            ["token": token
            ]){error in
                if let error = error{
                    print("Error while updating profile:  -\(error)")
                }else{
                    app.fcmToken = token
                    print("token is updated!")
                }
            }
    }
    
    func deleteFcmToken(token: String){
        guard let userId = auth.currentUser?.uid else{return}
        let ref = db.collection("users").document(userId).collection("fcmTokens").document(token)
        
        ref.delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
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
                    fromUID: notification.fromUID, isRead: notification.isRead,
                    status: notification.status,
                    type: notification.type,
                    relatedId: notification.relatedId
                )
                self.sendNotification(updatedNotification, fcmArray: [token])
            }
    }
    
    
    func sendNotification(_ notification: NotificationModel, fcmArray: [String]) {
        let data: [String: Any] = [
            "notificationId": notification.notificationId,
            "title": notification.title,
            "message": notification.message,
            "timestamp": Timestamp(date: notification.timestamp),
            "recipientUID": notification.recipientUID,
            "isRead": notification.isRead,
            "status": notification.status.rawValue,
            "type": notification.type.rawValue,
            "relatedId": notification.relatedId,
            "fromUID": notification.fromUID
        ]

        Firestore.firestore()
            .collection("notifications")
            .document(notification.notificationId)
            .setData(data) { error in
                if let error = error {
                    print("❌ Error sending notification: \(error.localizedDescription)")
                } else {
                    print("✅ Notification sent to \(notification.recipientUID)")
                }
            }

        // Send push notification via FCM
//        for token in fcmArray {
//            sendPushNotification(to: token, title: notification.title, body: notification.message)
//        }
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
}

