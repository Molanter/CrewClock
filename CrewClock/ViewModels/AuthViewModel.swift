//
//  AuthViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/27/25.
//

import SwiftUI
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var userName: String?
    @Published var userEmail: String?
    @Published var userToken: String?

    
    init() {
        checkIfSignedIn()
    }

    func checkIfSignedIn() {
        if let user = Auth.auth().currentUser {
            self.isSignedIn = true
            self.userName = user.displayName
            self.userEmail = user.email
            print("✅ Restored Firebase session: \(user.email ?? "")")
        }

        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            if let user = user {
                self?.userToken = user.accessToken.tokenString
                print("🟢 Restored Google access token: \(self?.userToken ?? "nil")")
            } else {
                print("⚠️ Google user not restored: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    //MARK: SignIn with Google
    func signInWithGoogle() {
        guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("❌ No root view controller")
            return
        }

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootVC,
            hint: nil,
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
                    self?.checkIfSignedIn()
                    
                    Messaging.messaging().token { token, error in
                        if let error = error {
                            print("Error fetching FCM registration token: \(error)")
                        } else if let token = token {
                            print("FCM registration token: \(token)")
                            // You can now store or update the token in Firestore
                            NotificationsViewModel().updateFcmToken(token: token)
                            app.fcmToken = token  // store in @AppStorage
                        }
                    }
                }
            }
        }
    }
    
    func setProfile() {
        if let user = Auth.auth().currentUser {
            let userData: [String: Any] = [
                "name": user.displayName ?? "",
                "email": user.email ?? "",
                "uid": user.uid,
                "profileImage": user.photoURL?.absoluteString ?? ""
            ]
            
            Firestore.firestore().collection("users").document(user.uid).setData(userData, merge: true)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            let notificationsVM = NotificationsViewModel()
            if let token = app.fcmToken {
                notificationsVM.deleteFcmToken(token: token)
            }
            self.isSignedIn = false
            self.userName = nil
            self.userEmail = nil
            print("✅ Successfully signed out.")
            self.checkIfSignedIn()
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
            self.checkIfSignedIn()
        }
    }
}
