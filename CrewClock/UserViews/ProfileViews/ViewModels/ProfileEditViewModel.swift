//
//  ProfileEditViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/3/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

@MainActor
final class ProfileEditViewModel: ObservableObject {
    // Form fields
    @Published var name: String = ""
    @Published var descriptionText: String = ""
    @Published var city: String = ""
    @Published var country: String = ""
    @Published var tags: [String] = []
    @Published var languages: [String] = []

    // Image picking
    @Published var pickerItem: PhotosPickerItem?
    @Published var avatarPreview: Image? // for UI
    private var avatarData: Data?

    // UI state
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var saveDone = false

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // Load current values from existing user
    func prefill(from user: UserFB?) {
        guard let u = user else { return }
        name = u.name
        descriptionText = u.description
        city = (Mirror(reflecting: u).descendant("city") as? String) ?? ""
        country = (Mirror(reflecting: u).descendant("country") as? String) ?? ""
        tags = (Mirror(reflecting: u).descendant("tags") as? [String]) ?? u.connections /* fallback not ideal */.filter { !$0.isEmpty }.prefix(0).map { $0 }
        languages = (Mirror(reflecting: u).descendant("languages") as? [String]) ?? []
    }

    func handlePickedPhoto() async {
        guard let item = pickerItem else { return }
        self.error = nil
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                self.avatarData = data
                if let ui = UIImage(data: data) {
                    self.avatarPreview = Image(uiImage: ui)
                }
            }
        } catch {
            self.error = "Failed to load image."
        }
    }

    private func uploadAvatar(to uid: String) async throws -> String {
        guard let data = avatarData else { return "" } // no change
        let ref = storage.reference().child("userProfiles/\(uid)/avatar.jpg")
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(data, metadata: meta)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    func save(userVM: UserViewModel) async {
        guard let uid = auth.currentUser?.uid else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }

        var updates: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "description": descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            "city": city.trimmingCharacters(in: .whitespacesAndNewlines),
            "country": country.trimmingCharacters(in: .whitespacesAndNewlines),
            "tags": tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
            "languages": languages.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        ]

        do {
            // Upload avatar if changed
            if let _ = avatarData {
                let url = try await uploadAvatar(to: uid)
                if !url.isEmpty { updates["profileImage"] = url }
            }

            try await db.collection("users").document(uid).updateData(updates)
            await MainActor.run {
                userVM.fetchUser()
                saveDone = true
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
    }
}
