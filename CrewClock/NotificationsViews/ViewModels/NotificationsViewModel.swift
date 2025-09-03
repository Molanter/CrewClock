//
//  NotificationsViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/21/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class NotificationsViewModel: ObservableObject {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    @Published var tokensArray: [String] = []
    @Published var notifications: [NotificationFB] = []

    // MARK: - FCM Tokens

    func updateFcmToken(token: String) {
        #if targetEnvironment(simulator)
        print("🧪 Simulator token detected; not storing: \(token)")
        return
        #endif

        guard let uid = auth.currentUser?.uid else {
            print("⚠️ updateFcmToken: no authenticated user")
            return
        }

        let ref = db.collection("users").document(uid)
            .collection("tokens")
            .document(token)

        ref.setData([
            "platform": "ios",
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("❌ Error updating FCM token: \(error.localizedDescription)")
            } else {
                app.fcmToken = token
                print("✅ Stored FCM token: \(token.prefix(12))…")
            }
        }
    }

    func deleteFcmToken(userId: String, token: String) {
        db.collection("users").document(userId)
            .collection("tokens")
            .document(token)
            .delete { err in
                if let err = err {
                    print("❌ Error removing FCM token: \(err.localizedDescription)")
                } else {
                    print("🧹 Removed FCM token: \(token.prefix(12))…")
                }
            }
    }

    // MARK: - Notifications (Create)

    /// Send to a single recipient UID (normalizes the model then delegates).
    func getFcmByUid(uid: String, notification: NotificationModel) {
        let normalized = NotificationModel(
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
        sendNotification(normalized)
    }

    /// Saves one Firestore doc per recipient; your Cloud Function (onCreate) will send the push.
    func sendNotification(_ notification: NotificationModel) {
        let baseId = notification.notificationId.isEmpty ? UUID().uuidString : notification.notificationId
        let recipients = notification.recipientUID

        for recipientUID in recipients {
            var data: [String: Any] = [
                "notificationId": baseId,
                "title": notification.title,
                "message": notification.message,
                "timestamp": Timestamp(date: notification.timestamp),
                "recipientUIDs": [recipientUID],            // ✅ plural array
                "fromUID": notification.fromUID,
                "isRead": notification.isRead,
                "status": notification.status.rawValue,
                "type": notification.type.rawValue,
                "relatedId": notification.relatedId as Any
            ]
            if let imageUrl = notification.imageUrl, imageUrl.hasPrefix("http") {
                data["imageUrl"] = imageUrl
            }

            let documentId = "\(baseId)_\(recipientUID)"
            db.collection("notifications").document(documentId).setData(data) { error in
                if let error = error {
                    print("❌ Error saving notification for \(recipientUID): \(error.localizedDescription)")
                } else {
                    print("✅ Notification saved (docId=\(documentId)) — onCreate will send push")
                }
            }
        }
    }

    // MARK: - Fetch

    /// Fetch notifications addressed to the current user.
    func fetchNotifications(completion: @escaping ([NotificationFB]) -> Void) {
        guard let uid = auth.currentUser?.uid else {
            completion([])
            return
        }

        db.collection("notifications")
            .whereField("recipientUIDs", arrayContains: uid)  // ✅ plural field
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error fetching notifications: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let docs = snapshot?.documents ?? []
                let items = docs.map { NotificationFB(data: $0.data(), documentId: $0.documentID) }

                DispatchQueue.main.async {
                    self?.notifications = items
                }

                print("✅ Notifications fetched:", items.count)
                completion(items)
            }
    }

    // MARK: - Update status

    /// Preferred: update by **documentId** ("<notificationId>_<recipientUID>").
    func updateNotificationStatus(documentId: String,
                                  newStatus: NotificationStatus,
                                  completion: ((Bool) -> Void)? = nil) {
        db.collection("notifications").document(documentId)
            .updateData(["status": newStatus.rawValue]) { [weak self] error in
                if let error = error {
                    print("❌ Error updating notification (docId=\(documentId)): \(error.localizedDescription)")
                    completion?(false)
                } else {
                    if let idx = self?.notifications.firstIndex(where: { $0.notificationId == documentId }) { // ✅ compare by documentId
                        self?.notifications[idx].status = newStatus
                    }
                    print("✅ Notification status updated for docId=\(documentId)")
                    completion?(true)
                }
            }
    }

    /// Back-compat: update by **notificationId** (looks up the current user's doc if needed).
    func updateNotificationStatus(notificationId: String,
                                  newStatus: NotificationStatus,
                                  completion: ((Bool) -> Void)? = nil) {
        let ref = db.collection("notifications").document(notificationId)
        ref.updateData(["status": newStatus.rawValue]) { [weak self] error in
            if let error = error {
                // Likely "No document to update" — fall back to query by fields.
                print("ℹ️ Direct update failed (\(error.localizedDescription)), trying lookup by fields…")
                guard let uid = self?.auth.currentUser?.uid else { completion?(false); return }

                self?.db.collection("notifications")
                    .whereField("notificationId", isEqualTo: notificationId)
                    .whereField("recipientUIDs", arrayContains: uid)
                    .limit(to: 1)
                    .getDocuments { snap, qErr in
                        if let qErr = qErr {
                            print("❌ Lookup failed: \(qErr.localizedDescription)")
                            completion?(false); return
                        }
                        guard let doc = snap?.documents.first else {
                            print("❌ No notification doc found for id=\(notificationId) & user=\(uid)")
                            completion?(false); return
                        }
                        self?.updateNotificationStatus(documentId: doc.documentID,
                                                       newStatus: newStatus,
                                                       completion: completion)
                    }
            } else {
                if let idx = self?.notifications.firstIndex(where: { $0.notificationId == notificationId }) {
                    self?.notifications[idx].status = newStatus
                }
                print("✅ Notification status updated for id=\(notificationId)")
                completion?(true)
            }
        }
    }
}
