//
//  LegacyImagePicker.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/4/25.
//


import SwiftUI
import UIKit

struct LegacyImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var allowsEditing: Bool = true
    var onImage: (UIImage) -> Void
    var onCancel: () -> Void = {}

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.sourceType = sourceType
        vc.allowsEditing = allowsEditing    // ← system crop UI
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LegacyImagePicker
        init(_ parent: LegacyImagePicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Use edited image if available, else original
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            if let img = image { parent.onImage(img) } else { parent.onCancel() }
        }
    }
}