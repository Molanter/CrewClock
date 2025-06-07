//
//  AuthViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/27/25.
//

import SwiftUI
import GoogleSignIn
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var userName: String?
    @Published var userEmail: String?

    
    init() {
        checkIfSignedIn()
    }

    func checkIfSignedIn() {
        if let user = Auth.auth().currentUser {
            self.isSignedIn = true
            self.userName = user.displayName
            self.userEmail = user.email
            print("✅ Restored session: \(user.email ?? "")")
        }
    }
    
    
    func signInWithGoogle() {
        guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("❌ No root view controller")
            return
        }

        let additionalScopes = [
            "https://www.googleapis.com/auth/spreadsheets",
            "https://www.googleapis.com/auth/drive.file"
        ]

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootVC,
            hint: nil,
            additionalScopes: additionalScopes
        ) { [weak self] result, error in
            if let error = error {
                print("❌ Google Sign-In failed: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("❌ Missing Google tokens")
                return
            }

            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("❌ Firebase sign-in error: \(error.localizedDescription)")
                    return
                }

                DispatchQueue.main.async {
                    self?.isSignedIn = true
                    self?.userName = user.profile?.name
                    self?.userEmail = user.profile?.email
                    print("✅ Signed in as \(user.profile?.email ?? "-")")
                    print("🟢 Access token for Google APIs: \(accessToken)")
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.isSignedIn = false
            self.userName = nil
            self.userEmail = nil
            print("✅ Successfully signed out.")
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
}
