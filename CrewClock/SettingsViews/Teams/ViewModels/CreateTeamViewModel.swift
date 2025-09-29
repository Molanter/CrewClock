//
//  CreateTeamViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/18/25.
//


import Foundation
import Combine
import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseFirestore


#if canImport(UIKit)
import UIKit
extension Color {
    func toHex() -> String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let ri = Int(round(r * 255)), gi = Int(round(g * 255)), bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
#endif // canImport(UIKit)

@MainActor
final class CreateTeamViewModel: ObservableObject {
    @Published var isCreating = false
    @Published var errorMessage = ""

    private let db = Firestore.firestore()

    /// Creates a team and returns the new teamId (doc ID) on success.
    func createTeam(name: String, image: String, color: Color) async -> String? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
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
        let hexColor = color.toHex() ?? "#000000"
        let data: [String: Any] = [
            "name": name,
            "image": image,
            "color": hexColor,
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

extension CreateTeamViewModel {
    @MainActor
    func updateTeam(
        teamId: String,
        name: String? = nil,
        image: String? = nil,
        color: Color? = nil
    ) async -> Bool {
        // Optional: mirror your create state with a separate updating flag
        isCreating = true
        defer { isCreating = false }

        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Not signed in."
            return false
        }

        // Prepare partial updates
        var updates: [String: Any] = [:]

        if let name = name {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                errorMessage = "Please enter a team name."
                return false
            }
            updates["name"] = trimmed
        }

        if let image = image {
            updates["image"] = image
        }

        if let color = color {
            #if canImport(UIKit)
            if let hex = color.toHex() {
                updates["color"] = hex           // store as hex string
            } else {
                updates["color"] = "#000000"     // fallback
            }
            #else
            updates["color"] = "unknown"         // non-UIKit platforms fallback
            #endif
        }

        // No-op guard
        guard !updates.isEmpty else {
            errorMessage = "Nothing to update."
            return false
        }

        // Common metadata updates
        updates["updatedAt"] = Date.now
        updates["updatedBy"] = uid

        do {
            let teamRef = db.collection("teams").document(teamId)
            try await teamRef.updateData(updates)
            return true
        } catch {
            errorMessage = "Failed to update team: \(error.localizedDescription)"
            return false
        }
    }
}
