//
//  TeamInvitesViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/6/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class TeamInvitesViewModel: ObservableObject {
    @Published var isWorking = false
    @Published var errorMessage: String = ""
    @Published var lastActionTeamId: String?

    private let db = Firestore.firestore()

    // MARK: - Public API

    /// Accept an invite: set teams/{teamId}/members/{me}.status = "active",
    /// then delete matching root notifications (type=teamInvite, relatedId=teamId, recipientUIDs contains me).
    func acceptInvite(teamId: String) async {
        await withBusy(teamId: teamId) {
            guard let me = Auth.auth().currentUser?.uid else {
                throw Self.err("Not signed in.")
            }

            // 1) Promote invitation to active in the subcollection (fits your Firestore rules)
            let memberRef = self.db.collection("teams").document(teamId).collection("members").document(me)
            try await memberRef.setData([
                "uid": me,
                "status": "active",
                "role": "member",
                "acceptedAt": Timestamp(date: Date())
            ], merge: true)

            // 2) Delete matching notifications
            try await self.deleteInviteNotifications(teamId: teamId, uid: me)
        }
    }

    /// Decline an invite: remove teams/{teamId}/members/{me} (or mark declined),
    /// then delete matching root notifications (type=teamInvite, relatedId=teamId, recipientUIDs contains me).
    func declineInvite(teamId: String, hardDeleteMemberDoc: Bool = true) async {
        await withBusy(teamId: teamId) {
            guard let me = Auth.auth().currentUser?.uid else {
                throw Self.err("Not signed in.")
            }

            let memberRef = self.db.collection("teams").document(teamId).collection("members").document(me)

            if hardDeleteMemberDoc {
                // Remove the pending membership doc entirely
                try await memberRef.delete()
            } else {
                // Or flip status to declined (kept for audit)
                try await memberRef.setData([
                    "uid": me,
                    "status": "declined",
                    "role": "member",
                    "declinedAt": Timestamp(date: Date())
                ], merge: true)
            }

            // Delete matching notifications
            try await self.deleteInviteNotifications(teamId: teamId, uid: me)
        }
    }

    // MARK: - Internals

    /// Finds and deletes all root notifications that represent this invite:
    /// collection("notifications")
    ///   .whereField("type", in: ["teamInvite","team_invite"])
    ///   .whereField("relatedId", isEqualTo: teamId)
    ///   .whereField("recipientUIDs", arrayContains: uid)
    private func deleteInviteNotifications(teamId: String, uid: String) async throws {
        let types = ["teamInvite", "team_invite"]

        // Firestore doesn't allow 3 where clauses with "in" + "arrayContains" *and* requires an index.
        // Your console already prompted an index for similar queries; if needed you may build separate queries.
        let query = db.collection("notifications")
            .whereField("type", in: types)
            .whereField("relatedId", isEqualTo: teamId)
            .whereField("recipientUIDs", arrayContains: uid)

        let snap = try await query.getDocuments()
        guard !snap.documents.isEmpty else { return }

        // Batch delete in chunks of 400 (limit 500, but keep headroom)
        var docs = snap.documents
        while !docs.isEmpty {
            let chunk = Array(docs.prefix(400))
            docs.removeFirst(chunk.count)

            let batch = db.batch()
            for d in chunk { batch.deleteDocument(d.reference) }
            try await batch.commit()
        }
    }

    // MARK: - Helpers

    private func withBusy(teamId: String, _ work: @escaping () async throws -> Void) async {
        errorMessage = ""
        lastActionTeamId = teamId
        isWorking = true
        defer { isWorking = false }
        do {
            try await work()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func err(_ msg: String) -> NSError {
        NSError(domain: "TeamInvitesVM", code: 1, userInfo: [NSLocalizedDescriptionKey: msg])
    }
}
