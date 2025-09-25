//
//  CreateTeamViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/18/25.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class CreateTeamViewModel: ObservableObject {
    @Published var teamName: String = ""
    @Published var isCreating = false
    @Published var errorMessage = ""

    private let db = Firestore.firestore()

    /// Creates a team and returns the new teamId (doc ID) on success.
    func createTeam() async -> String? {
        let name = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            errorMessage = "Please enter a team name."
            return nil
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Not signed in."
            return nil
        }

        isCreating = true
        defer { isCreating = false }

        let teamRef = db.collection("teams").document()
        let ownerEntry: [String: Any] = [
            "uid": uid,
            "role": "owner",
            "addedAt": Date.now
        ]
        let data: [String: Any] = [
            "name": name,
            "owner_uid": uid,
            "createdAt": Date.now,
            "ownerUid": uid,
            "members": [ownerEntry]
        ]

        do {
            try await teamRef.setData(data)
            return teamRef.documentID
        } catch {
            errorMessage = "Failed to create team: \(error.localizedDescription)"
            return nil
        }
    }
}
