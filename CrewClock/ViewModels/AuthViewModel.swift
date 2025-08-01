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
import AuthenticationServices
import CryptoKit

class AuthViewModel: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var userName: String?
    @Published var userEmail: String?
    @Published var userToken: String?

    private var currentNonce: String?

    
    override init() {
        super.init()
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
    //MARK: Sign Ins
    ///SignIn with Google
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
    
    ///SignIn with Emai+Password
    func signInWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let user = result?.user {
                completion(.success(user))
                self.checkIfSignedIn()
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }
    
    ///SignIn with Apple
    func handleAppleSignIn() {
            let nonce = randomNonceString()
            currentNonce = nonce

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        private func sha256(_ input: String) -> String {
            let inputData = Data(input.utf8)
            let hashed = SHA256.hash(data: inputData)
            return hashed.compactMap { String(format: "%02x", $0) }.joined()
        }

        private func randomNonceString(length: Int = 32) -> String {
            let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
            var result = ""
            var remainingLength = length

            while remainingLength > 0 {
                let random = UInt8.random(in: 0...255)
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }

            return result
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


extension AuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Error getting Apple token")
                return
            }

            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase Apple sign-in error: \(error.localizedDescription)")
                } else {
                    print("Signed in with Apple")
                    self.checkIfSignedIn()
                    // You can publish user data here if needed
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign-In failed: \(error.localizedDescription)")
        self.checkIfSignedIn()
    }
}

extension AuthViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
    }
}
