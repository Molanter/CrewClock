//
//  ProfileCompletenessViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/4/25.
//


import SwiftUI
import FirebaseAuth

// Checks whether the current user's profile is complete and controls gating UI
@MainActor
final class ProfileCompletenessViewModel: ObservableObject {
    @Published var isIncomplete: Bool = false
    @Published var missing: [String] = []
    @Published var showGate: Bool = false   // trigger full-screen gate

    func evaluate(with user: UserFB?) {
        guard let u = user else {
            isIncomplete = true
            missing = ["name","description","tags","languages","location"]
            showGate = true
            return
        }
        let descOK = !u.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let tagsOK = !(Mirror(reflecting: u).descendant("tags") as? [String] ?? []).isEmpty
        let langsOK = !(Mirror(reflecting: u).descendant("languages") as? [String] ?? []).isEmpty
        let city = (Mirror(reflecting: u).descendant("city") as? String) ?? ""
        let country = (Mirror(reflecting: u).descendant("country") as? String) ?? ""
        let locationOK = !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        var missingItems: [String] = []
        if !descOK { missingItems.append("description") }
        if !tagsOK { missingItems.append("tags") }
        if !langsOK { missingItems.append("language") }
        if !locationOK { missingItems.append("location") }

        self.isIncomplete = !missingItems.isEmpty
        self.missing = missingItems
        self.showGate = self.isIncomplete
    }
}
