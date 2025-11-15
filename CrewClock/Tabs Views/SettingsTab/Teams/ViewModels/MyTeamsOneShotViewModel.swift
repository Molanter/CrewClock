//
//  MyTeamsOneShotViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/14/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class MyTeamsOneShotViewModel: ObservableObject {
    // MARK: - Published state
    @Published var owned: [TeamFB] = []        // teams I own
    @Published var memberOf: [TeamFB] = []     // status == active (excluding teams I own)
    @Published var invitedTo: [TeamFB] = []    // status == invited
    @Published var errorMessage: String?
    @Published var isLoading = false

    // MARK: - Firestore
    private let db = Firestore.firestore()

    // MARK: - Public API

    /// Fetch all relevant teams once and store them in memory.
    func load() async {
        guard let me = Auth.auth().currentUser?.uid else {
            owned = []; memberOf = []; invitedTo = []
            errorMessage = "Not signed in."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            async let ownedTeams  = fetchOwnedTeams(me: me)
            async let activeTeams = fetchMembershipTeams(me: me, status: .active)
            async let invited     = fetchMembershipTeams(me: me, status: .invited)

            var (ownedResult, activeResult, invitedResult) = try await (ownedTeams, activeTeams, invited)

            // Same behavior as your listener VM: exclude teams I own from memberOf
            activeResult.removeAll { $0.ownerUid == me }

            ownedResult.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            activeResult.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            invitedResult.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            self.owned = ownedResult
            self.memberOf = activeResult
            self.invitedTo = invitedResult

            // Optional: hydrate members once if you need member roles/status locally
            await hydrateMembersOnce(for: ownedResult.map(\.id), into: .owned)
            await hydrateMembersOnce(for: activeResult.map(\.id), into: .active)
            await hydrateMembersOnce(for: invitedResult.map(\.id), into: .invited)

        } catch {
            self.errorMessage = error.localizedDescription
            self.owned = []
            self.memberOf = []
            self.invitedTo = []
        }

        isLoading = false
    }

    var invites: [TeamFB] { invitedTo }

    func isOwner(of team: TeamFB) -> Bool {
        guard let me = Auth.auth().currentUser?.uid else { return false }
        return team.ownerUid == me
    }

    // MARK: - Fetch helpers

    private func fetchOwnedTeams(me: String) async throws -> [TeamFB] {
        let snap = try await db.collection("teams")
            .whereField("ownerUid", isEqualTo: me)
            .getDocuments()

        let docs = snap.documents
        return docs.map(mapTeam)
    }

    /// Fetch teams where `teams/{id}/members/{me}.status == status`.
    private func fetchMembershipTeams(me: String, status: TeamMemberStatus) async throws -> [TeamFB] {
        let snap = try await db.collectionGroup("members")
            .whereField("uid", isEqualTo: me)
            .whereField("status", isEqualTo: status.rawValue)
            .getDocuments()

        let memberDocs = snap.documents
        // parent of members/{doc} is "members", parent of that is the team doc
        let teamIDs = Array(Set(memberDocs.compactMap { $0.reference.parent.parent?.documentID }))
        if teamIDs.isEmpty { return [] }

        return try await fetchTeams(ids: teamIDs)
    }

    /// Fetch team documents by IDs with chunked IN queries.
    private func fetchTeams(ids: [String]) async throws -> [TeamFB] {
        let chunks = ids.chunked(into: 10)
        var all: [TeamFB] = []

        for chunk in chunks {
            let snap = try await db.collection("teams")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            let docs = snap.documents
            let mapped = docs.map(mapTeam)
            all.append(contentsOf: mapped)
        }

        return all
    }

    // MARK: - Member hydration (one-shot)

    private enum Bucket { case owned, active, invited }

    /// Load members from `teams/{id}/members` once and fill the local arrays.
    private func hydrateMembersOnce(for teamIds: [String], into bucket: Bucket) async {
        guard !teamIds.isEmpty else { return }

        for teamId in teamIds {
            do {
                let snap = try await db.collection("teams")
                    .document(teamId)
                    .collection("members")
                    .getDocuments()

                let docs = snap.documents
                let entries = docs.map(mapMemberDoc)

                switch bucket {
                case .owned:
                    if let idx = owned.firstIndex(where: { $0.id == teamId }) {
                        owned[idx].members = entries
                    }
                case .active:
                    if let idx = memberOf.firstIndex(where: { $0.id == teamId }) {
                        memberOf[idx].members = entries
                    }
                case .invited:
                    if let idx = invitedTo.firstIndex(where: { $0.id == teamId }) {
                        invitedTo[idx].members = entries
                    }
                }
            } catch {
                // Surface error but do not fail everything
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Mapping helpers

    private func mapTeam(_ d: DocumentSnapshot) -> TeamFB {
        let name  = d["name"] as? String ?? "Untitled"
        let owner = d["ownerUid"] as? String ?? ""
        let image = d["image"] as? String ?? ""
        let color = decodeColor(from: d)
        // members will be hydrated later
        return TeamFB(id: d.documentID, name: name, ownerUid: owner, members: [], image: image, color: color)
    }

    private func mapMemberDoc(_ d: QueryDocumentSnapshot) -> TeamMemberEntry {
        let uid = d.documentID
        let roleStr = (d["role"] as? String)?.lowercased() ?? "member"
        let statusStr = (d["status"] as? String)?.lowercased() ?? "active"
        let addedAt: Date? = (d["addedAt"] as? Timestamp)?.dateValue()
            ?? (d["addedAt"] as? Date)
            ?? nil
        let role: TeamRole = TeamRole(rawValue: roleStr) ?? .member
        let status: TeamMemberStatus = TeamMemberStatus(rawValue: statusStr) ?? .active
        return TeamMemberEntry(uid: uid, role: role, status: status, addedAt: addedAt)
    }

    private func decodeColor(from d: DocumentSnapshot) -> Color {
        if let hex = d["color"] as? String {
            #if canImport(UIKit)
            if let c = Color(hex: hex) { return c }
            #endif
        }
        if let rgb = d["color"] as? [String: Any],
           let rAny = rgb["r"], let gAny = rgb["g"], let bAny = rgb["b"] {
            let r = (rAny as? Double) ?? Double((rAny as? NSNumber)?.doubleValue ?? 0)
            let g = (gAny as? Double) ?? Double((gAny as? NSNumber)?.doubleValue ?? 0)
            let b = (bAny as? Double) ?? Double((bAny as? NSNumber)?.doubleValue ?? 0)
            let scale: Double = (r > 1.0 || g > 1.0 || b > 1.0) ? 255.0 : 1.0
            return Color(red: r/scale, green: g/scale, blue: b/scale)
        }
        return .blue
    }
}
