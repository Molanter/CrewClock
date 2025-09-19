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
            // 1) Load current team doc to compute diffs & get team name (optional)
            let teamRef = db.collection("teams").document(teamId)
            let snap = try await teamRef.getDocument()
            var teamName: String = (snap["name"] as? String) ?? "your team"

            // existing members as array of maps
            let existing = (snap["members"] as? [[String: Any]]) ?? []
            var existingByUID: [String: Int] = [:]  // uid -> index in existing
            for (idx, m) in existing.enumerated() {
                if let uid = m["uid"] as? String {
                    existingByUID[uid] = idx
                }
            }

            // 2) Compute who is new
            let newUIDs = members.filter { existingByUID[$0] == nil }
            guard !newUIDs.isEmpty else {
                // Nothing new to add; nothing to notify.
                return true
            }

            // 3) Build updated array: keep old entries, append new invited entries
            var updated = existing
            for uid in newUIDs {
                updated.append([
                    "uid": uid,
                    "role": "member",
                    "status": "invited",
                    "addedAt": Date.now
                ])
            }

            // 4) Persist full array (owner-only ‘members’ update; matches your rules)
            try await teamRef.setData(["members": updated], merge: true)

            // 5) Send push notifications to newUIDs
            // Choose your enum case. If you don’t have `.teamInvite`, reuse `.connectInvite`.
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
                    type: NotificationType.teamInite,
                    relatedId: teamId             // point at the team
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
