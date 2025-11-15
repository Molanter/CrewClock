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
final class AddMembersToTeamViewModel: ObservableObject {
    @Published var members: [String] = []   // user UIDs
    @Published var errorMessage = ""
    @Published var isSaving = false

    private let db = Firestore.firestore()
    private let notificationsVM = NotificationsViewModel()

    /// Saves selected members into the subcollection:
    ///    teams/{teamId}/members/{uid}  (document id = uid)
    /// and sends push invites to only the *newly added* UIDs.
    ///
    /// Each subcollection doc has:
    /// { uid: String, role: "member", status: "invited", addedAt: Timestamp }
    /// NOTE: This no longer writes to teams/{teamId}.members (array of maps).
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

            // Read team name for notifications (read-only; we won't modify the team doc fields)
            let teamSnap = try await teamRef.getDocument()
            let teamName = (teamSnap["name"] as? String) ?? "your team"

            // Fetch existing member docs in the subcollection to avoid duplicates
            let membersCol = teamRef.collection("members")
            let existingSnap = try await membersCol.getDocuments()

            // Build a set of existing UIDs from subcollection document IDs
            var existingByUID = Set<String>(existingSnap.documents.map { $0.documentID })

            // Selected user UIDs
            let selectedUserIds: [String] = members

            // Determine which selected UIDs are new (not already present)
            let newUIDs = selectedUserIds.filter { !existingByUID.contains($0) }
            guard !newUIDs.isEmpty else { return true }

            // Create/merge subcollection member docs: teams/{teamId}/members/{uid}
            let now = Timestamp(date: Date())
            let batch = db.batch()
            for uid in newUIDs {
                let memberRef = membersCol.document(uid) // doc id == uid
                batch.setData([
                    "uid": uid,
                    "role": "member",
                    "status": "invited",
                    "addedAt": now
                ], forDocument: memberRef, merge: true)
            }

            try await batch.commit()

            // Send notifications to the newly invited users
            let title = "Invite to join \(teamName)"
            let msg   = "\(senderName) invited you to join \(teamName). Open CrewClock to accept."
            for uid in newUIDs {
                let notif = NotificationModel(
                    title: title,
                    message: msg,
                    timestamp: Date(),
                    recipientUID: [uid],
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
