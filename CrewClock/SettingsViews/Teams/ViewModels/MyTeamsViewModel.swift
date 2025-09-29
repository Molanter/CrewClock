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

#if canImport(UIKit)
private extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6,
              let r = Int(s.prefix(2), radix: 16),
              let g = Int(s.dropFirst(2).prefix(2), radix: 16),
              let b = Int(s.dropFirst(4).prefix(2), radix: 16) else {
            return nil
        }
        self = Color(
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0
        )
    }
}
#endif

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
    
    private func decodeColor(from d: DocumentSnapshot) -> Color {
        // Hex string like "#RRGGBB"
        if let hex = d["color"] as? String {
            #if canImport(UIKit)
            if let c = Color(hex: hex) { return c }
            #endif
        }
        // Dictionary like { "r": 79, "g": 70, "b": 229 } or { "r": 0.31, "g": 0.27, "b": 0.90 }
        if let rgb = d["color"] as? [String: Any],
           let rAny = rgb["r"], let gAny = rgb["g"], let bAny = rgb["b"] {
            let r = (rAny as? Double) ?? Double((rAny as? NSNumber)?.doubleValue ?? 0)
            let g = (gAny as? Double) ?? Double((gAny as? NSNumber)?.doubleValue ?? 0)
            let b = (bAny as? Double) ?? Double((bAny as? NSNumber)?.doubleValue ?? 0)
            let scale: Double = (r > 1.0 || g > 1.0 || b > 1.0) ? 255.0 : 1.0
            return Color(red: r / scale, green: g / scale, blue: b / scale)
        }
        // Fallback
        return .blue
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
                    let color = self.decodeColor(from: d)
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
                        let color = self.decodeColor(from: d)
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
        let teamRef = db.collection("teams").document(teamId)
        teamRef.getDocument { [weak self] snap, err in
            guard let self else { return }
            if let err {
                self.errorMessage = err.localizedDescription
                self.isLoading = false
                completion?(err)
                return
            }
            guard let snap, snap.exists,
                  var members = snap["members"] as? [[String: Any]] else {
                let error = NSError(domain: "MyTeams", code: 404,
                                    userInfo: [NSLocalizedDescriptionKey: "Team not found or members missing"])
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion?(error)
                return
            }
            // Filter out the member to remove
            members.removeAll { ($0["uid"] as? String) == memberUid }
            teamRef.updateData(["members": members]) { err in
                if let err {
                    self.errorMessage = err.localizedDescription
                } else {
                    // Update local state
                    func removeMemberFromArray(_ arr: inout [TeamFB]) {
                        if let tIdx = arr.firstIndex(where: { $0.id == teamId }) {
                            arr[tIdx].members.removeAll(where: { $0.uid == memberUid })
                        }
                    }
                    removeMemberFromArray(&self.owned)
                    removeMemberFromArray(&self.memberOf)
                    self.start() // optionally refresh listeners
                }
                self.isLoading = false
                completion?(err)
            }
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
    /// Multiple owners allowed. You cannot demote the last remaining owner.
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
                completion?(err)
                return
            }
            guard let snap, snap.exists,
                  var membersRaw = snap["members"] as? [[String: Any]] else {
                let error = NSError(domain: "MyTeams", code: 404,
                                    userInfo: [NSLocalizedDescriptionKey: "Team not found or members missing"])
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion?(error)
                return
            }
            // Decode members to TeamMemberEntry for convenience
            var members = membersRaw.compactMap { m -> TeamMemberEntry? in
                guard let uid = m["uid"] as? String else { return nil }
                let roleStr = (m["role"] as? String)?.lowercased() ?? "member"
                let role = TeamRole(rawValue: roleStr) ?? .member
                let statusStr = (m["status"] as? String)?.lowercased() ?? "active"
                let status = TeamMemberStatus(rawValue: statusStr) ?? .active
                let addedAt: Date? = (m["addedAt"] as? Timestamp)?.dateValue()
                    ?? (m["addedAt"] as? Date)
                    ?? nil
                return TeamMemberEntry(uid: uid, role: role, status: status, addedAt: addedAt)
            }

            let ownersCount = members.filter { $0.role == .owner }.count
            let isDemotion = (newRole != .owner)
            let thisIsOwner = members.contains(where: { $0.uid == memberUid && $0.role == .owner })

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

            // Update the role of the member
            if let idx = members.firstIndex(where: { $0.uid == memberUid }) {
                members[idx].role = newRole
            } else {
                // Insert if not present
                members.append(TeamMemberEntry(uid: memberUid, role: newRole, status: .active, addedAt: nil))
            }

            // Convert back to raw dictionary array for Firestore update
            membersRaw = members.map {
                var dict: [String: Any] = [
                    "uid": $0.uid,
                    "role": $0.role.rawValue,
                    "status": $0.status.rawValue
                ]
                if let addedAt = $0.addedAt {
                    dict["addedAt"] = Timestamp(date: addedAt)
                }
                return dict
            }

            teamRef.updateData(["members": membersRaw]) { err in
                if let err {
                    self.errorMessage = err.localizedDescription
                    self.isLoading = false
                    completion?(err)
                    return
                }

                // Update local state
                func apply(_ arr: inout [TeamFB]) {
                    if let tIdx = arr.firstIndex(where: { $0.id == teamId }) {
                        if let mIdx = arr[tIdx].members.firstIndex(where: { $0.uid == memberUid }) {
                            arr[tIdx].members[mIdx].role = newRole
                        } else {
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
