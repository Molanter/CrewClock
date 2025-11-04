//
//  ProfileViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/3/25.
//


import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var viewedUser: UserFB?
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()
    private let auth = Auth.auth()

    /// Resolve target uid. If nil, returns current user's uid or nil if not signed in.
    func resolveUid(_ uid: String?) -> String? {
        if let uid, !uid.isEmpty { return uid }
        return auth.currentUser?.uid
    }

    /// Load user document for the provided uid (or current user if nil).
    func loadUser(uid: String?) {
        error = nil
        guard let target = resolveUid(uid) else {
            viewedUser = nil
            return
        }
        isLoading = true
        db.collection("users").document(target).getDocument(source: .default) { [weak self] snap, err in
            guard let self else { return }
            self.isLoading = false
            if let err {
                self.error = err.localizedDescription
                self.viewedUser = nil
                return
            }
            guard let data = snap?.data() else {
                self.viewedUser = nil
                return
            }
            self.viewedUser = UserFB(data: data, documentId: snap?.documentID ?? target)
        }
    }

    /// Compute the connection record status between the signed-in user and `otherUid`.
    /// Pass in the current `connections` array from ConnectionsViewModel.
    func connectionStatus(with otherUid: String, connections: [Connection]) -> ConnectionStatus? {
        guard let me = auth.currentUser?.uid else { return nil }
        return connections
            .first(where: { $0.uids.contains(me) && $0.uids.contains(otherUid) })?
            .status
    }

    /// True if the viewed profile belongs to the signed-in user.
    func isSelf(viewedUid: String?) -> Bool {
        guard let me = auth.currentUser?.uid, let v = viewedUid else { return false }
        return me == v
    }
}
