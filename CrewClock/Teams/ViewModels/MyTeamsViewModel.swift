//
//  MyTeamsViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/18/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Convenience expected by the app
// Remove if you already define these.

extension TeamFB {
    func status(for uid: String) -> TeamMemberStatus? {
        members.first(where: { $0.uid == uid })?.status
    }
}

#if canImport(UIKit)
private extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6,
              let r = Int(s.prefix(2), radix: 16),
              let g = Int(s.dropFirst(2).prefix(2), radix: 16),
              let b = Int(s.dropFirst(4), radix: 16) else { return nil }
        self = Color(red: Double(r)/255.0, green: Double(g)/255.0, blue: Double(b)/255.0)
    }
}
#endif

@MainActor
final class MyTeamsViewModel: ObservableObject {
    // MARK: - Published state
    @Published var owned: [TeamFB] = []        // teams I own
    @Published var memberOf: [TeamFB] = []     // status == active
    @Published var invitedTo: [TeamFB] = []    // status == invited
    @Published var errorMessage: String = ""
    @Published var isLoading = false

    // MARK: - Firestore
    private let db = Firestore.firestore()
    private var ownedListener: ListenerRegistration?
    private var memberCGListener: ListenerRegistration?
    private var invitedCGListener: ListenerRegistration?
    
    deinit {
        ownedListener?.remove()
        memberCGListener?.remove()
        invitedCGListener?.remove()
    }

    // MARK: - Lifecycle
    func start() {
        guard let me = Auth.auth().currentUser?.uid else {
            owned = []; memberOf = []; invitedTo = []
            errorMessage = "Not signed in."
            return
        }
        errorMessage = ""
        isLoading = true
        listenOwned(me)
        listenMemberships(me: me, status: TeamMemberStatus.active.rawValue)   // -> memberOf
        listenMemberships(me: me, status: TeamMemberStatus.invited.rawValue)  // -> invitedTo
    }

    var invites: [TeamFB] { invitedTo }
    func isOwner(of team: TeamFB) -> Bool {
        guard let me = Auth.auth().currentUser?.uid else { return false }
        return team.ownerUid == me
    }

    // MARK: - Owned teams

    private func listenOwned(_ me: String) {
        ownedListener?.remove()
        ownedListener = db.collection("teams")
            .whereField("ownerUid", isEqualTo: me)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    self.errorMessage = err.localizedDescription
                    self.isLoading = false
                    return
                }
                let docs = snap?.documents ?? []
                let teams = docs.map(self.mapTeam)
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                self.owned = teams
                // hydrate members from subcollection
                self.loadMembers(for: teams.map { $0.id }, into: .owned)
                self.isLoading = false
            }
    }

    /// Listens to teams where `teams/{id}/members/{me}.status == status` and
    /// keeps the corresponding array (active -> memberOf, invited -> invitedTo) in sync.
    /// Also filters out teams I own from `memberOf`.
    private func listenMemberships(me: String, status: String) {
        // Tear down the previous listener for this status
        if status == "active" { memberCGListener?.remove() }
        if status == "invited" { invitedCGListener?.remove() }

        let listener = db.collectionGroup("members")
            .whereField("uid", isEqualTo: me)
            .whereField("status", isEqualTo: status)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }

                if let err {
                    self.errorMessage = err.localizedDescription
                    self.applyTeams([], forStatus: status)
                    self.isLoading = false
                    return
                }

                let memberDocs = snap?.documents ?? []
                // parent of members/{doc} is "members", parent of that is the team doc
                let teamIDs = Array(Set(memberDocs.compactMap { $0.reference.parent.parent?.documentID }))

                // No teams? Clear and bail.
                if teamIDs.isEmpty {
                    self.applyTeams([], forStatus: status)
                    self.isLoading = false
                    return
                }

                // Fetch parent team docs in chunks of 10 (limit of Firestore `in` queries)
                self.fetchTeams(ids: teamIDs) { teams, fetchErr in
                    if let fetchErr {
                        self.errorMessage = fetchErr.localizedDescription
                        self.applyTeams([], forStatus: status)
                        self.isLoading = false
                        return
                    }

                    // Sort
                    var allTeams = teams
                        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

                    // 🔹 If we're filling `memberOf` (status == active), exclude teams I own
                    if status == TeamMemberStatus.active.rawValue {
                        allTeams.removeAll { $0.ownerUid == me }
                    }

                    // Apply to the correct bucket
                    self.applyTeams(allTeams, forStatus: status)

                    // Hydrate members from subcollection for these teams
                    self.loadMembers(for: allTeams.map { $0.id },
                                     into: (status == TeamMemberStatus.active.rawValue ? .active : .invited))

                    self.isLoading = false
                }
            }

        if status == "active" {
            memberCGListener = listener
        } else if status == "invited" {
            invitedCGListener = listener
        }
    }
    // MARK: - Hydration from subcollection

    private enum Bucket { case owned, active, invited }

    /// Load members from `teams/{id}/members` and write them into the right published array.
    private func loadMembers(for teamIds: [String], into bucket: Bucket) {
        guard !teamIds.isEmpty else { return }

        for teamId in teamIds {
            let membersRef = db.collection("teams").document(teamId).collection("members")
            membersRef.getDocuments { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    // Don’t fail the whole view; just surface the error once.
                    self.errorMessage = err.localizedDescription
                    return
                }
                let docs = snap?.documents ?? []
                let entries = docs.map(self.mapMemberDoc)

                // Update the right array item by id
                switch bucket {
                case .owned:
                    if let idx = self.owned.firstIndex(where: { $0.id == teamId }) {
                        self.owned[idx].members = entries
                    }
                case .active:
                    if let idx = self.memberOf.firstIndex(where: { $0.id == teamId }) {
                        self.memberOf[idx].members = entries
                    }
                case .invited:
                    if let idx = self.invitedTo.firstIndex(where: { $0.id == teamId }) {
                        self.invitedTo[idx].members = entries
                    }
                }
            }
        }
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

    /// Applies fetched teams to the right published array based on member status.
    private func applyTeams(_ teams: [TeamFB], forStatus status: String) {
        if status == "active" {
            self.memberOf = teams
        } else if status == "invited" {
            self.invitedTo = teams
        }
    }

    /// Fetch team documents by IDs with chunked IN queries.
    private func fetchTeams(ids: [String], completion: @escaping ([TeamFB], Error?) -> Void) {
        let chunks = ids.chunked(into: 10)
        var all: [TeamFB] = []
        var lastError: Error?
        let group = DispatchGroup()

        for chunk in chunks {
            group.enter()
            db.collection("teams")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { snap, err in
                    defer { group.leave() }
                    if let err { lastError = err; return }
                    let docs = snap?.documents ?? []
                    let mapped = docs.map(self.mapTeam)
                    all.append(contentsOf: mapped)
                }
        }

        group.notify(queue: .main) {
            completion(all, lastError)
        }
    }

    // MARK: - Mapping helpers

    private func mapTeam(_ d: DocumentSnapshot) -> TeamFB {
        let name  = d["name"] as? String ?? "Untitled"
        let owner = d["ownerUid"] as? String ?? ""
        let image = d["image"] as? String ?? ""
        let color = decodeColor(from: d)
        // members are hydrated from subcollection later
        return TeamFB(id: d.documentID, name: name, ownerUid: owner, members: [], image: image, color: color)
    }

    // (kept for color decoding; members array is no longer read)
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

    // MARK: - Actions (unchanged; still update legacy array if present)

    func removeMember(teamId: String, memberUid: String, completion: ((Error?) -> Void)? = nil) {
        if let team = (owned + memberOf + invitedTo).first(where: { $0.id == teamId }),
           team.ownerUid == memberUid {
            let err = NSError(domain: "MyTeams", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Owner cannot be removed."])
            self.errorMessage = err.localizedDescription
            completion?(err)
            return
        }

        isLoading = true
        let teamRef = db.collection("teams").document(teamId)
        let memberRef = teamRef.collection("members").document(memberUid)

        Task {
            do {
                // 1) Remove subcollection member doc
                try await memberRef.delete()

                // 2) Keep legacy members array in sync (if it exists)
                let snap = try await teamRef.getDocument()
                if var membersArr = snap["members"] as? [[String: Any]] {
                    membersArr.removeAll { ($0["uid"] as? String) == memberUid }
                    try await teamRef.updateData(["members": membersArr])
                }

                // prune local mirrors
                func prune(_ arr: inout [TeamFB]) {
                    if let t = arr.firstIndex(where: { $0.id == teamId }) {
                        arr[t].members.removeAll { $0.uid == memberUid }
                    }
                }
                prune(&self.owned); prune(&self.memberOf); prune(&self.invitedTo)
                self.isLoading = false
                completion?(nil)
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion?(error)
            }
        }
    }

    func leaveTeam(teamId: String) {
        guard let me = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Not signed in."; return
        }
        removeMember(teamId: teamId, memberUid: me) { [weak self] err in
            if let err { self?.errorMessage = err.localizedDescription }
        }
    }

    func deleteTeam(teamId: String, completion: ((Error?) -> Void)? = nil) {
        guard let me = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Not signed in."
            completion?(NSError(domain: "MyTeams", code: 401,
                                userInfo: [NSLocalizedDescriptionKey: "Not signed in."]))
            return
        }
        isLoading = true
        let ref = db.collection("teams").document(teamId)
        ref.getDocument { [weak self] snap, err in
            guard let self else { return }
            if let err {
                self.errorMessage = err.localizedDescription
                self.isLoading = false
                completion?(err); return
            }
            guard let snap, snap.exists, (snap["ownerUid"] as? String) == me else {
                let e = NSError(domain: "MyTeams", code: 403,
                                userInfo: [NSLocalizedDescriptionKey: "Only the owner can delete this team."])
                self.errorMessage = e.localizedDescription
                self.isLoading = false
                completion?(e); return
            }
            // Consider recursive delete for subcollections
            ref.delete { err in
                if let err { self.errorMessage = err.localizedDescription }
                self.owned.removeAll { $0.id == teamId }
                self.memberOf.removeAll { $0.id == teamId }
                self.invitedTo.removeAll { $0.id == teamId }
                self.isLoading = false
                completion?(err)
            }
        }
    }

    // MARK: - Roles (still supported with legacy array for your UI)

    func changeRoleWithOwnerGuard(
        teamId: String,
        memberUid: String,
        newRole: TeamRole,
        completion: ((Error?) -> Void)? = nil
    ) {
        isLoading = true
        let teamRef = db.collection("teams").document(teamId)
        teamRef.getDocument { [weak self] snap, err in
            guard let self else { return }
            if let err {
                self.errorMessage = err.localizedDescription
                self.isLoading = false
                completion?(err); return
            }
            guard let snap, snap.exists,
                  var membersRaw = snap["members"] as? [[String: Any]] else {
                let e = NSError(domain: "MyTeams", code: 404,
                                userInfo: [NSLocalizedDescriptionKey: "Team not found or members missing"])
                self.errorMessage = e.localizedDescription
                self.isLoading = false
                completion?(e); return
            }

            // Decode -> enforce owner rule
            var ownersCount = 0
            var foundIndex: Int?
            for (i, m) in membersRaw.enumerated() {
                if (m["role"] as? String)?.lowercased() == "owner" { ownersCount += 1 }
                if (m["uid"] as? String) == memberUid { foundIndex = i }
            }
            let isDemotion = (newRole != .owner)
            let targetWasOwner = foundIndex != nil && (membersRaw[foundIndex!]["role"] as? String)?.lowercased() == "owner"
            if isDemotion && targetWasOwner && ownersCount <= 1 {
                let e = NSError(domain: "MyTeams", code: 1001,
                                userInfo: [NSLocalizedDescriptionKey: "You can’t change this role: this is the only owner on the team."])
                self.errorMessage = e.localizedDescription
                self.isLoading = false
                completion?(e); return
            }

            // Apply new role in legacy array
            if let idx = foundIndex {
                membersRaw[idx]["role"] = newRole.rawValue
            } else {
                membersRaw.append([
                    "uid": memberUid,
                    "role": newRole.rawValue,
                    "status": "active",
                    "addedAt": Timestamp(date: Date())
                ])
            }

            teamRef.updateData(["members": membersRaw]) { err in
                if let err {
                    self.errorMessage = err.localizedDescription
                    self.isLoading = false
                    completion?(err); return
                }

                // Mirror to subcollection
                teamRef.collection("members").document(memberUid)
                    .setData(["uid": memberUid, "role": newRole.rawValue], merge: true)

                // Update local caches
                func apply(_ arr: inout [TeamFB]) {
                    if let tIdx = arr.firstIndex(where: { $0.id == teamId }) {
                        if let mIdx = arr[tIdx].members.firstIndex(where: { $0.uid == memberUid }) {
                            arr[tIdx].members[mIdx].role = newRole
                        } else {
                            arr[tIdx].members.append(.init(uid: memberUid, role: newRole, status: .active, addedAt: nil))
                        }
                    }
                }
                apply(&self.owned); apply(&self.memberOf); apply(&self.invitedTo)
                self.isLoading = false
                completion?(nil)
            }
        }
    }
}

