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

        if recipients.isEmpty {
            print("❌ No recipients — not writing notification.")
            return
        }

        for uid in recipients {
            guard let data = buildNotificationData(baseId: baseId, recipientUID: uid, notification: notification) else {
                continue // skip invalid payloads
            }

            let documentId = "\(baseId)_\(uid)"
            db.collection("notifications").document(documentId).setData(data) { error in
                if let error = error {
                    print("❌ Error saving notification for \(uid): \(error.localizedDescription)")
                } else {
                    print("✅ Notification saved (docId=\(documentId)) — onCreate will send push")
                }
            }
        }
    }

    /// Build and validate the exact schema your onCreate function expects.
    private func buildNotificationData(
        baseId: String,
        recipientUID: String,
        notification: NotificationModel
    ) -> [String: Any]? {

        // Determine sender: prefer auth user; fallback to model's fromUID
        let currentUID = auth.currentUser?.uid ?? notification.fromUID

        // Normalize strings
        let title = notification.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = notification.message.trimmingCharacters(in: .whitespacesAndNewlines)
        let typeString = notification.type.rawValue
        let recipient = recipientUID.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate requireds (match server expectations)
        var missing: [String] = []
        if baseId.isEmpty { missing.append("notificationId") }
        if title.isEmpty { missing.append("title") }
        if message.isEmpty { missing.append("message") }
        if recipient.isEmpty { missing.append("recipientUID") }
        if currentUID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("fromUID") }
        if typeString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("type") }

        if !missing.isEmpty {
            print("❌ Missing required fields: \(missing.joined(separator: ", ")) — aborting write.")
            return nil
        }

        var data: [String: Any] = [
            "notificationId": baseId,
            "title": title,
            "message": message,
            "timestamp": FieldValue.serverTimestamp(),   // server time is safest for backend validation
            "recipientUIDs": [recipient],               // plural array (non-empty)
            "fromUID": currentUID,
            "isRead": notification.isRead,
            "status": notification.status.rawValue,
            "type": typeString
        ]

        // relatedId is a non-optional String in your model (compile error showed that),
        // so just check emptiness.
        let related = notification.relatedId
        if !related.isEmpty {
            data["relatedId"] = related
        }

        if let url = notification.imageUrl, url.hasPrefix("http") {
            data["imageUrl"] = url
        }

        return data
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
                    // ✅ compare by documentId (not notificationId)
                    if let idx = self?.notifications.firstIndex(where: { $0.notificationId == documentId }) {
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
