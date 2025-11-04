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
    // Keep original selected image so the user can crop/zoom before upload
    @Published var avatarOriginal: UIImage?
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
                    self.avatarOriginal = ui
                    self.avatarPreview = Image(uiImage: ui)
                }
            }
        } catch {
            self.error = "Failed to load image."
        }
    }

    /// Set the picked avatar image and prepare data for upload.
    func setAvatarImage(_ image: UIImage) {
        self.avatarOriginal = image
        self.avatarPreview  = Image(uiImage: image)
        self.avatarData     = image.jpegData(compressionQuality: 0.9)
    }

    private func uploadAvatar(to uid: String) async throws -> String {
        guard let data = avatarData else { return "" } // no change
        let ref = storage.reference().child("users/\(uid)/profilePictures/avatar.jpg")
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
    /// Apply a square crop based on the interactive state from the crop UI.
    /// - Parameters:
    ///   - viewportSize: The size of the crop viewport in points (square).
    ///   - contentOffset: The current pan offset applied to the image inside the viewport (points).
    ///   - scale: The current zoom scale applied to the image.
    func applySquareCrop(viewportSize: CGSize, contentOffset: CGSize, scale: CGFloat) {
        guard let base = avatarOriginal else { return }

        // Compute how the base image is fitted in the viewport at scale=1.
        let imageSize = CGSize(width: base.size.width, height: base.size.height)
        let aspect = imageSize.width / imageSize.height
        var fittedSize: CGSize
        if aspect > 1 {
            // Wider than tall: width fits viewport
            fittedSize = CGSize(width: viewportSize.width, height: viewportSize.width / aspect)
        } else {
            // Taller than wide: height fits viewport
            fittedSize = CGSize(width: viewportSize.height * aspect, height: viewportSize.height)
        }

        // Apply user zoom
        let displayedSize = CGSize(width: fittedSize.width * scale, height: fittedSize.height * scale)

        // Image origin (top-left) inside viewport after panning.
        // Center image then apply offset.
        let originX = (viewportSize.width  - displayedSize.width)  / 2.0 + contentOffset.width
        let originY = (viewportSize.height - displayedSize.height) / 2.0 + contentOffset.height

        // The crop rect is the viewport bounds (0,0,viewportSize).
        // Map it into image pixel space.
        // For a point P in viewport, corresponding point in image is:
        // ((P.x - originX) / displayedSize.width) * imageSize.width, similar for y.
        func toImageSpace(_ p: CGPoint) -> CGPoint {
            let nx = (p.x - originX) / displayedSize.width
            let ny = (p.y - originY) / displayedSize.height
            return CGPoint(x: nx * imageSize.width, y: ny * imageSize.height)
        }
        let topLeft     = toImageSpace(.zero)
        let bottomRight = toImageSpace(CGPoint(x: viewportSize.width, y: viewportSize.height))

        var crop = CGRect(
            x: min(topLeft.x, bottomRight.x),
            y: min(topLeft.y, bottomRight.y),
            width: abs(bottomRight.x - topLeft.x),
            height: abs(bottomRight.y - topLeft.y)
        ).integral

        // Clamp crop to image bounds
        crop = crop.intersection(CGRect(origin: .zero, size: imageSize))
        guard crop.width > 0, crop.height > 0 else { return }

        // Perform crop
        guard let cg = base.cgImage,
              let sub = cg.cropping(to: crop) else { return }
        let cropped = UIImage(cgImage: sub, scale: base.scale, orientation: base.imageOrientation)

        // Update preview and data to upload
        self.avatarPreview = Image(uiImage: cropped)
        self.avatarData = cropped.jpegData(compressionQuality: 0.9)
    }
}
