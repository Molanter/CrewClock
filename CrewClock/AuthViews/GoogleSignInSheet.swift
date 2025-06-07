//
//  GoogleSignInSheet.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/27/25.
//

import SwiftUI
import UIKit

struct GoogleSignInSheet: UIViewControllerRepresentable {
    @ObservedObject var viewModel: AuthViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                viewModel.signInWithGoogle()
            } else {
                print("⚠️ Could not find root view controller to present Google Sign-In")
            }
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
