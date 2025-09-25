//
//  AddMembersViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/24/25.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AddMembersViewModel: ObservableObject {
    @Published var members: [String] = []   // UIDs selected in the UI
    @Published var errorMessage = ""
    @Published var isSaving = false

    private let db = Firestore.firestore()
    private let notificationsVM = NotificationsViewModel()

    /// Saves selected members into teams/{teamId}.members (array of maps)
    /// and sends push invites to only the *newly added* UIDs.
    ///
    /// Each member map looks like:
    /// { uid: String, role: "member", status: "invited", addedAt: <server timestamp> }
    ///
    /// - Parameters:
    ///   - teamId: team doc id
    ///   - senderName: name to show in the notification ("Alice")
    ///   - senderUid: the inviter's uid (usually current user)
    func saveMembersAndNotify(teamId: String, senderName: String, senderUid: String) async -> Bool {
        guard !members.isEmpty else {
            errorMessage = "Add at least one member."
            return false
        }

        isSaving = true
        defer { isSaving = false }
        errorMessage = ""

        do {
            let teamRef = db.collection("teams").document(teamId)
            let snap = try await teamRef.getDocument()

            let teamName = (snap["name"] as? String) ?? "your team"
            let existing = (snap["members"] as? [[String: Any]]) ?? []

            // Build lookup of existing member UIDs
            var existingByUID = Set<String>()
            for m in existing {
                if let uid = m["uid"] as? String { existingByUID.insert(uid) }
            }

            // Who is new?
            let newUIDs = members.filter { !existingByUID.contains($0) }
            guard !newUIDs.isEmpty else { return true }

            // Append Firestore-safe entries
            var updated = existing
            for uid in newUIDs {
                updated.append([
                    "uid": uid,
                    "role": "member",                     // String, not enum
                    "status": "invited",
                    "addedAt": FieldValue.serverTimestamp() // or Timestamp(date: Date())
                ])
            }

            // Persist array
            try await teamRef.setData(["members": updated], merge: true)

            // Notify the new folks
            let title = "Invite to join \(teamName)"
            let msg   = "\(senderName) invited you to join \(teamName). Open CrewClock to accept."
            for uid in newUIDs {
                let notif = NotificationModel(
                    title: title,
                    message: msg,
                    timestamp: Date(),
                    recipientUID: [uid],            // keep your model shape
                    fromUID: senderUid,
                    isRead: false,
                    type: NotificationType.teamInvite,
                    relatedId: teamId
                )
                notificationsVM.getFcmByUid(uid: uid, notification: notif)
            }

            return true
        } catch {
            errorMessage = "Failed to save members: \(error.localizedDescription)"
            return false
        }
    }
}