//
//  TeamFB.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/18/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TeamFB: Identifiable {
    let id: String
    let name: String
    let ownerUid: String
    let memberCount: Int
}

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

    private func listenOwned(_ me: String) {
        ownedListener?.remove()
        ownedListener = db.collection("teams")
            .whereField("ownerUid", isEqualTo: me)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err { self.errorMessage = err.localizedDescription; return }
                let docs = snap?.documents ?? []
                self.owned = docs.map { d in
                    let name = d["name"] as? String ?? "Untitled"
                    let owner = d["ownerUid"] as? String ?? ""
                    let members = d["members"] as? [[String:Any]] ?? []
                    return TeamFB(id: d.documentID, name: name, ownerUid: owner, memberCount: members.count)
                }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                self.isLoading = false
            }
    }

    private func listenMemberOf(_ me: String) {
        memberListener?.remove()
        // Requires a derived field: membersUIDs: [String]
        memberListener = db.collection("teams")
            .whereField("membersUIDs", arrayContains: me)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err { self.errorMessage = err.localizedDescription; return }
                let docs = snap?.documents ?? []
                self.memberOf = docs
                    .filter { ($0["ownerUid"] as? String) != me } // don’t duplicate owned
                    .map { d in
                        let name = d["name"] as? String ?? "Untitled"
                        let owner = d["ownerUid"] as? String ?? ""
                        let members = d["members"] as? [[String:Any]] ?? []
                        return TeamFB(id: d.documentID, name: name, ownerUid: owner, memberCount: members.count)
                    }
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                self.isLoading = false
            }
    }
}