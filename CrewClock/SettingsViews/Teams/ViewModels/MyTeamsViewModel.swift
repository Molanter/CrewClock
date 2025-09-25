//
//  MyTeamsViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/18/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class MyTeamsViewModel: ObservableObject {
    @Published var owned: [TeamFB] = []
    @Published var memberOf: [TeamFB] = []
    @Published var errorMessage: String = ""
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var ownedListener: ListenerRegistration?
    private var memberListener: ListenerRegistration?
    
    deinit {
        ownedListener?.remove()
        memberListener?.remove()
    }
    
    func start() {
        guard let me = Auth.auth().currentUser?.uid else {
            self.owned = []; self.memberOf = []
            self.errorMessage = "Not signed in."
            return
        }
        isLoading = true
        listenOwned(me)
        listenMemberOf(me)
    }
    
    // MARK: - Decoding
    private func decodeMembers(from d: DocumentSnapshot) -> [TeamMemberEntry] {
        let raw = (d["members"] as? [[String: Any]]) ?? []
        return raw.compactMap { m in
            guard let uid = m["uid"] as? String else { return nil }
            
            // role
            let roleStr = (m["role"] as? String)?.lowercased() ?? "member"
            let role: TeamRole = TeamRole(rawValue: roleStr) ?? .member
            
            // status (enum you just added)
            let statusStr = (m["status"] as? String)?.lowercased() ?? "active"
            let status: TeamMemberStatus = TeamMemberStatus(rawValue: statusStr) ?? .active
            
            // addedAt
            let addedAt: Date? = (m["addedAt"] as? Timestamp)?.dateValue()
                ?? (m["addedAt"] as? Date)
                ?? nil
            
            return TeamMemberEntry(uid: uid, role: role, status: status, addedAt: addedAt)
        }
    }
    
    // MARK: - Listeners
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
                self.owned = docs.map { d in
                    let name  = d["name"] as? String ?? "Untitled"
                    let owner = d["ownerUid"] as? String ?? ""
                    let image = d["image"] as? String ?? ""
                    let color = Color.blue // TODO: decode if you store color
                    let members = self.decodeMembers(from: d)
                    return TeamFB(id: d.documentID, name: name, ownerUid: owner, members: members, image: image, color: color)
                }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                self.isLoading = false
            }
    }

    private func listenMemberOf(_ me: String) {
        memberListener?.remove()
        // Using derived array; if you migrate fully to subcollection, swap to collectionGroup("members") with .whereField("uid", isEqualTo: me)
        memberListener = db.collection("teams")
            .whereField("membersUIDs", arrayContains: me)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    self.errorMessage = err.localizedDescription
                    self.isLoading = false
                    return
                }
                let docs = snap?.documents ?? []
                self.memberOf = docs
                    .filter { ($0["ownerUid"] as? String) != me } // don’t duplicate owned
                    .map { d in
                        let name  = d["name"] as? String ?? "Untitled"
                        let owner = d["ownerUid"] as? String ?? ""
                        let image = d["image"] as? String ?? ""
                        let color = Color.blue
                        let members = self.decodeMembers(from: d)
                        return TeamFB(id: d.documentID, name: name, ownerUid: owner, members: members, image: image, color: color)
                    }
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                self.isLoading = false
            }
    }
}

// MARK: - Remove
extension MyTeamsViewModel {
    func removeMember(
        teamId: String,
        memberUid: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        // block removing the owner
        if let team = (owned + memberOf).first(where: { $0.id == teamId }),
           team.ownerUid == memberUid {
            let err = NSError(domain: "MyTeams", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Owner cannot be removed."])
            self.errorMessage = err.localizedDescription
            completion?(err)
            return
        }

        isLoading = true
        db.collection("teams")
            .document(teamId)
            .collection("members")
            .document(memberUid)
            .delete { [weak self] err in
                guard let self else { return }
                if let err {
                    self.errorMessage = err.localizedDescription
                } else {
                    self.start() // or optimistically mutate local arrays
                }
                self.isLoading = false
                completion?(err)
            }
    }

    /// Current user leaves a team (UID only).
    func leaveTeam(teamId: String) {
        guard let me = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Not signed in."
            return
        }
        removeMember(teamId: teamId, memberUid: me) { [weak self] err in
            if let err { self?.errorMessage = err.localizedDescription }
        }
    }
}

// MARK: - Update roles
extension MyTeamsViewModel {
    // Seed an owner subdoc if missing, so rules see you as a manager.
    // Safe to call repeatedly; it's a no-op if the doc exists.
    private func ensureOwnerSubdoc(teamId: String) async {
        guard let me = Auth.auth().currentUser?.uid else { return }
        let teamRef = db.collection("teams").document(teamId)

        do {
            // If you want to rely on ownerUid too, you can check it here:
            let teamSnap = try await teamRef.getDocument()
            let ownerUid = teamSnap["ownerUid"] as? String

            // Only seed if the current user IS the owner of the team doc
            guard ownerUid == me else { return }

            let myMemberRef = teamRef.collection("members").document(me)
            let mySnap = try await myMemberRef.getDocument()
            if !mySnap.exists {
                try await myMemberRef.setData([
                    "uid": me,
                    "role": "owner",
                    "status": "active"
                ])
            }
        } catch {
            // swallow — if this fails, the following update will fail and surface the error anyway
        }
    }
    
    /// Multiple owners allowed. You cannot demote the last remaining owner.
    func changeRoleWithOwnerGuard(
        teamId: String,
        memberUid: String,
        newRole: TeamRole,
        completion: ((Error?) -> Void)? = nil
    ) {
        isLoading = true
        Task { [weak self] in
            guard let self else { return }
            // 0) Make sure the caller is “visible” to rules as an owner (seed subdoc if needed)
            await self.ensureOwnerSubdoc(teamId: teamId)

            let teamRef = self.db.collection("teams").document(teamId)
            let memRef  = teamRef.collection("members").document(memberUid)

            // 1) Load current owners to guard last-owner demotion
            teamRef.collection("members")
                .whereField("role", isEqualTo: "owner")
                .getDocuments { [weak self] snap, err in
                    guard let self else { return }
                    if let err {
                        self.errorMessage = err.localizedDescription
                        self.isLoading = false
                        completion?(err)
                        return
                    }

                    let ownerDocs   = snap?.documents ?? []
                    let ownersCount = ownerDocs.count
                    let isDemotion  = (newRole != .owner)
                    let thisIsOwner = ownerDocs.contains { $0.documentID == memberUid }

                    if isDemotion && thisIsOwner && ownersCount <= 1 {
                        let e = NSError(
                            domain: "MyTeams",
                            code: 1001,
                            userInfo: [NSLocalizedDescriptionKey:
                                       "You can’t change this role: this is the only owner on the team."]
                        )
                        self.errorMessage = e.localizedDescription
                        self.isLoading = false
                        completion?(e)
                        return
                    }

                    // 2) Apply the role update
                    let roleValue = newRole.rawValue
                    memRef.setData(["uid": memberUid, "role": roleValue], merge: true) { [weak self] err in
                        guard let self else { return }
                        if let err {
                            self.errorMessage = err.localizedDescription
                            self.isLoading = false
                            completion?(err)
                            return
                        }

                        // 3) Update local state
                        func apply(_ arr: inout [TeamFB]) {
                            if let tIdx = arr.firstIndex(where: { $0.id == teamId }) {
                                if let mIdx = arr[tIdx].members.firstIndex(where: { $0.uid == memberUid }) {
                                    arr[tIdx].members[mIdx].role = newRole
                                } else {
                                    // optionally insert if row wasn’t present
                                    arr[tIdx].members.append(.init(uid: memberUid, role: newRole))
                                }
                            }
                        }
                        apply(&self.owned)
                        apply(&self.memberOf)

                        self.isLoading = false
                        completion?(nil)
                    }
                }
        }
    }
}

// MARK: - Accept invite (parent array model)
extension MyTeamsViewModel {
    /// Accept an invite for the current user in a given team.
    func acceptInvite(teamId: String, completion: ((Error?) -> Void)? = nil) async {
        guard let me = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Not signed in."
            completion?(NSError(domain: "MyTeams", code: 401,
                                userInfo: [NSLocalizedDescriptionKey: "Not signed in."]))
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            let teamRef = db.collection("teams").document(teamId)
            let snap = try await teamRef.getDocument()

            guard var members = snap["members"] as? [[String: Any]] else {
                throw NSError(domain: "MyTeams", code: 404,
                              userInfo: [NSLocalizedDescriptionKey: "Team members not found."])
            }

            if let idx = members.firstIndex(where: { ($0["uid"] as? String) == me }) {
                var entry = members[idx]
                entry["status"] = "active"
                entry["acceptedAt"] = Timestamp(date: Date())
                members[idx] = entry

                try await teamRef.updateData(["members": members])
            } else {
                throw NSError(domain: "MyTeams", code: 404,
                              userInfo: [NSLocalizedDescriptionKey: "Invite not found."])
            }

            self.isLoading = false
            completion?(nil)
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            completion?(error)
        }
    }
}
