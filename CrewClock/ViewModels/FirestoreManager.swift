//
//  FirestoreManager.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/9/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

enum FirestoreManagerError: Error {
    case encodingNotSupported
}

final class FirestoreManager {
    private let db: Firestore
    private let notificationsVM = NotificationsViewModel()
    private let userVM = UserViewModel()

    init(db: Firestore = .firestore()) { self.db = db }

    /// Create with optional document ID in a collection path, returns new docID.
    /// Pass raw Firestore data. Models do NOT need to conform to Encodable.
    @discardableResult
    func add(
        _ data: [String: Any],
        to collection: FirestoreCollectionPath,
        docID: String? = nil,
        notify: Bool = false,
        notifyType: NotificationType? = nil,
        notifyRecipients: [String] = [],
        notifyTitleOverride: String? = nil,
        notifyMessageOverride: String? = nil
    ) async throws -> String {
        var payload = data
        payload["createdAt"] = FieldValue.serverTimestamp()
        payload["updatedAt"] = FieldValue.serverTimestamp()
        let ref = docID != nil ? collection.col(in: db).document(docID!) : collection.col(in: db).document()
        try await ref.setData(payload)
        let docID = ref.documentID
        if notify {
            self.afterNotify(
                documentID: docID,
                data: payload,
                type: notifyType,
                recipients: notifyRecipients,
                titleOverride: notifyTitleOverride,
                messageOverride: notifyMessageOverride
            )
        }
        return docID
    }

    /// Upsert to a specific document path, returns document ID.
    /// Pass raw Firestore data. Models do NOT need to conform to Encodable.
    @discardableResult
    func upsert(
        _ data: [String: Any],
        at path: FirestorePath,
        merge: Bool = true,
        notify: Bool = false,
        notifyType: NotificationType? = nil,
        notifyRecipients: [String] = [],
        notifyTitleOverride: String? = nil,
        notifyMessageOverride: String? = nil
    ) async throws -> String {
        var payload = data
        if merge {
            payload["updatedAt"] = FieldValue.serverTimestamp()
        } else {
            payload["createdAt"] = FieldValue.serverTimestamp()
            payload["updatedAt"] = FieldValue.serverTimestamp()
        }
        try await path.doc(in: db).setData(payload, merge: merge)
        let docID = path.doc(in: db).documentID
        if notify {
            self.afterNotify(
                documentID: docID,
                data: payload,
                type: notifyType,
                recipients: notifyRecipients,
                titleOverride: notifyTitleOverride,
                messageOverride: notifyMessageOverride
            )
        }
        return docID
    }

    @available(*, deprecated, message: "Use the dictionary-based add(_:to:docID:) instead.")
    func add<T: Encodable>(_ value: T, to collection: FirestoreCollectionPath, docID: String? = nil, extra: [String: Any] = [:]) async throws -> String {
        throw FirestoreManagerError.encodingNotSupported
    }
    
    @available(*, deprecated, message: "Use the dictionary-based upsert(_:at:merge:) instead.")
    func upsert<T: Encodable>(_ value: T, at path: FirestorePath, merge: Bool = true, extra: [String: Any] = [:]) async throws -> String {
        throw FirestoreManagerError.encodingNotSupported
    }
    
    /// Delete a document at the given path.
    func delete(at path: FirestorePath) async throws {
        try await path.doc(in: db).delete()
    }
    
    /// Unified notifier used by add/upsert when `notify == true`.
    func afterNotify(
        documentID: String,
        data: [String: Any],
        type: NotificationType?,
        recipients: [String],
        titleOverride: String?,
        messageOverride: String?
    ) {
        guard let type = type, !recipients.isEmpty else { return }
        let currentUser = Auth.auth().currentUser
        let name = userVM.user?.name ?? "Def_not_me"
        let fromUID = currentUser?.uid ?? ""

        let title = titleOverride ?? type.title

        let message = messageOverride ?? "\(name) \(type.message)"

        let newNotification = NotificationModel(
            title: title,
            message: message,
            timestamp: Date(),
            recipientUID: recipients,
            fromUID: fromUID,
            isRead: false,
            type: type,
            relatedId: documentID
        )

        // Send to each recipient through the existing path
        for uid in recipients {
            notificationsVM.getFcmByUid(uid: uid, notification: newNotification)
        }
    }

}
