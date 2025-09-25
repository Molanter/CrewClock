//
//  TeamMembershipCheckerViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/24/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class TeamMembershipCheckerViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isInAnyTeam = false
    @Published var teamIds: [String] = []           // optional: the teams found
    @Published var errorMessage = ""

    private let db = Firestore.firestore()
    private var ownerListener: ListenerRegistration?
    private var memberListener: ListenerRegistration?

    deinit {
        ownerListener?.remove()
        memberListener?.remove()
    }

    /// One-shot check. Calls completion when done.
    func refresh(completion: (() -> Void)? = nil) {
        guard let me = Auth.auth().currentUser?.uid else {
            self.isInAnyTeam = false
            self.teamIds = []
            self.errorMessage = "Not signed in."
            completion?()
            return
        }

        isLoading = true
        errorMessage = ""
        teamIds = []

        // 1) check ownership (fast)
        db.collection("teams")
            .whereField("ownerUid", isEqualTo: me)
            .limit(to: 1)
            .getDocuments { [weak self] ownerSnap, ownerErr in
                guard let self else { return }

                if let ownerErr {
                    self.errorMessage = ownerErr.localizedDescription
                    self.isLoading = false
                    completion?()
                    return
                }

                if let doc = ownerSnap?.documents.first {
                    self.isInAnyTeam = true
                    self.teamIds = [doc.documentID]
                    self.isLoading = false
                    completion?()
                    return
                }

                // 2) not an owner — check membership via collectionGroup("members")
                self.db.collectionGroup("members")
                    .whereField("uid", isEqualTo: me)                    .limit(to: 1)
                    .getDocuments { [weak self] memSnap, memErr in
                        guard let self else { return }

                        if let memErr {
                            self.errorMessage = memErr.localizedDescription
                            self.isLoading = false
                            completion?()
                            return
                        }

                        if let memDoc = memSnap?.documents.first {
                            // parent of parent is the team doc
                            if let teamRef = memDoc.reference.parent.parent {
                                self.isInAnyTeam = true
                                self.teamIds = [teamRef.documentID]
                            } else {
                                self.isInAnyTeam = true // still true; we found a membership
                            }
                        } else {
                            self.isInAnyTeam = false
                            self.teamIds = []
                        }

                        self.isLoading = false
                        completion?()
                    }
            }
    }

    /// Live updates: keeps `isInAnyTeam` up to date.
    /// Call `startListening()` and `stopListening()` as needed (e.g., onAppear/onDisappear).
    func startListening() {
        guard let me = Auth.auth().currentUser?.uid else {
            self.isInAnyTeam = false
            self.teamIds = []
            self.errorMessage = "Not signed in."
            return
        }

        isLoading = true
        errorMessage = ""
        teamIds = []

        ownerListener?.remove()
        memberListener?.remove()

        // Listen to ownership
        ownerListener = db.collection("teams")
            .whereField("ownerUid", isEqualTo: me)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    self.errorMessage = err.localizedDescription
                    return
                }
                let ownedIds = (snap?.documents ?? []).map { $0.documentID }
                self.mergeAndPublish(ownedIds: ownedIds)
            }

        // Listen to membership via collectionGroup on "members"
        memberListener = db.collectionGroup("members")
            .whereField(FieldPath.documentID(), isEqualTo: me)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    self.errorMessage = err.localizedDescription
                    return
                }
                // Map each member doc back up to its team id
                let memberTeamIds: [String] = (snap?.documents ?? []).compactMap { $0.reference.parent.parent?.documentID }
                self.mergeAndPublish(memberIds: memberTeamIds)
            }

        isLoading = false
    }

    func stopListening() {
        ownerListener?.remove(); ownerListener = nil
        memberListener?.remove(); memberListener = nil
    }

    // MARK: - Helpers

    private var latestOwnedIds: Set<String> = []
    private var latestMemberIds: Set<String> = []

    private func mergeAndPublish(ownedIds: [String]? = nil, memberIds: [String]? = nil) {
        if let ownedIds { latestOwnedIds = Set(ownedIds) }
        if let memberIds { latestMemberIds = Set(memberIds) }

        let union = latestOwnedIds.union(latestMemberIds)
        self.teamIds = Array(union)
        self.isInAnyTeam = !union.isEmpty
    }
}
