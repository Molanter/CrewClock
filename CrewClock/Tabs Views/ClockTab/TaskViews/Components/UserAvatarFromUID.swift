//
//  UserAvatarFromUID.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/15/25.
//

import SwiftUI
import FirebaseFirestore

struct UserAvatarFromUID: View {
    let uid: String

    @State private var imageURL: String?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let imageURL {
                UserProfileImageRoundCorner(imageURL)
            } else {
                // Simple placeholder while loading or if missing
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            }
        }
        .task(id: uid) {
            await loadProfileImageURL()
        }
    }

    private func loadProfileImageURL() async {
        guard !isLoading, imageURL == nil else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let doc = try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .getDocument()

            if let data = doc.data(),
               let url = data["profileImage"] as? String {
                await MainActor.run {
                    self.imageURL = url
                }
            }
        } catch {
            // You can log the error if needed
             print("Failed to load profile image URL for \(uid): \(error)")
        }
    }
}
