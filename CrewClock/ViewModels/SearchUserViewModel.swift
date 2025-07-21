//
//  SearchUserViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/20/25.
//


import FirebaseFirestore
import SwiftUI

class SearchUserViewModel: ObservableObject {
    @Published var foundUIDs: [String] = []

    func searchUsers(with query: String) {
        guard !query.isEmpty else {
            foundUIDs = []
            return
        }

        Firestore.firestore().collection("users")
            .whereField("name", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("name", isLessThanOrEqualTo: query.lowercased() + "\u{f8ff}")
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let nameUIDs = documents.map { $0.documentID }
                    self.searchByEmailFallback(nameUIDs, query: query)
                } else {
                    self.foundUIDs = []
                }
            }
    }

    private func searchByEmailFallback(_ currentUIDs: [String], query: String) {
        Firestore.firestore().collection("users")
            .whereField("email", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("email", isLessThanOrEqualTo: query.lowercased() + "\u{f8ff}")
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let emailUIDs = documents.map { $0.documentID }
                    let combined = Array(Set(currentUIDs + emailUIDs))
                    self.foundUIDs = combined
                    print("searchUserViewModel.foundUIDs: -- ", self.foundUIDs)
                } else {
                    self.foundUIDs = currentUIDs
                }
            }
    }
}
