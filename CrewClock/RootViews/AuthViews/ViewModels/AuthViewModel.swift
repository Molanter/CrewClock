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

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
    @Published var userName: String?
    @Published var userEmail: String?
    @Published var userToken: String?

    private var currentNonce: String?

    private let auth = Auth.auth()

    override init() {
        super.init()
        // Manual bootstrap without auth listeners
        checkIfSignedIn()
        restoreGoogleIfPossible()
    }

    
    @MainActor
    func checkIfSignedIn() {
        if let user = auth.currentUser {
            userName = user.displayName
            userEmail = user.email
            print("✅ Firebase session active: \(user.email ?? "")")
            NotificationCenter.default.post(name: .authDidSignIn, object: nil)
        } else {
            userName = nil
            userEmail = nil
            print("ℹ️ No active Firebase session")
        }
    }

    // MARK: - Session bootstrap

    func restoreGoogleIfPossible() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            guard let self else { return }
            if let error = error {
                print("⚠️ Google user not restored: \(error.localizedDescription)")
                self.userToken = nil
                return
            }
            guard let gUser = user else {
                print("ℹ️ No previous Google session")
                self.userToken = nil
                return
            }
            gUser.refreshTokensIfNeeded { _, err in
                if let err = err {
                    print("⚠️ Failed to refresh Google tokens: \(err.localizedDescription)")
                    self.userToken = nil
                    return
                }
                let token = gUser.accessToken.tokenString
                self.userToken = token
                print("🟢 Restored Google access token: \(token)")
            }
        }
    }

    // MARK: - Sign-ins

    func signInWithGoogle() {
        guard
            let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        else {
            print("❌ No root view controller")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC, hint: nil) { [weak self] result, error in
            guard let self else { return }
            if let error = error {
                print("❌ Google Sign-In failed: \(error.localizedDescription)")
                return
            }
            guard
                let gUser = result?.user,
                let idToken = gUser.idToken?.tokenString
            else {
                print("❌ Missing Google tokens")
                return
            }

            let accessToken = gUser.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("❌ Firebase sign-in error: \(error.localizedDescription)")
                    return
                }

                if let user = authResult?.user {
                    self.setProfile(user: user)
                }
                if let u = authResult?.user {
                    NotificationCenter.default.post(name: .authDidSignIn, object: nil)
                    
                    self.userName = u.displayName
                    self.userEmail = u.email
                }
                print("✅ Signed in as \(gUser.profile?.email ?? "-")")
                print("🟢 Access token for Google APIs: \(accessToken)")

                // Fetch and store FCM token after Firebase sign-in.
                Messaging.messaging().token { token, error in
                    if let error = error {
                        print("⚠️ FCM token fetch error: \(error.localizedDescription)")
                    } else if let token = token {
                        print("📨 FCM token: \(token)")
                        NotificationsViewModel().updateFcmToken(token: token)
                        app.fcmToken = token
                    }
                }
            }
        }
    }

    func signInWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let user = result?.user {
                completion(.success(user))
                self?.setProfile(user: user)
                NotificationCenter.default.post(name: .authDidSignIn, object: nil)
                self?.userName = user.displayName
                self?.userEmail = user.email
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }

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

    // MARK: - Profile

    func setProfile(user: FirebaseAuth.User,
                    overrideName: String? = nil,
                    overridePhotoURL: URL? = nil) {
        let googleProfile = user.providerData.first { $0.providerID == "google.com" }

        let bestName = overrideName ?? user.displayName ?? googleProfile?.displayName ?? "Someone"

        var photo = overridePhotoURL?.absoluteString
        ?? user.photoURL?.absoluteString
        ?? googleProfile?.photoURL?.absoluteString
        ?? ""

        if photo.contains("googleusercontent.com"), !photo.contains("=s"), !photo.contains("?sz=") {
            photo += (photo.contains("?") ? "&" : "?") + "sz=256"
        }

        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "",
            "name": bestName,
            "profileImage": photo,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .setData(userData, merge: true) { error in
                if let error = error {
                    print("⚠️ setProfile Firestore error: \(error.localizedDescription)")
                } else {
                    print("💾 setProfile saved for \(bestName) - \(user.email ?? "") | photo: \(photo.isEmpty ? "none" : photo)")
                }
            }
    }

    // MARK: - Sign out

    func signOut() {
        // Stop user-scoped listeners first if you have them.
//        app.stopAllUserScopedListeners?()

        // Best-effort FCM cleanup before auth is cleared.
        
        if let uid = auth.currentUser?.uid, let token = app.fcmToken {
            NotificationsViewModel().deleteFcmToken(userId: uid, token: token)
        }

        do {
            // tell views/VMs to quiesce first
            NotificationCenter.default.post(name: .sessionWillEnd, object: nil)

            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()

            app.fcmToken = nil
            self.userName = nil
            self.userEmail = nil

            // now tell UI to switch branches
            NotificationCenter.default.post(name: .authDidSignOut, object: nil)

            print("✅ Successfully signed out.")
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
}

// MARK: - Apple Sign-In delegates

extension AuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            print("❌ Error getting Apple token")
            return
        }

        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)

        Auth.auth().signIn(with: credential) { [weak self] result, error in
            if let error = error {
                print("❌ Firebase Apple sign-in error: \(error.localizedDescription)")
                return
            }
            guard let self else { return }
            print("✅ Signed in with Apple")
            if let user = result?.user {
                self.setProfile(user: user)
                self.userName = user.displayName
                self.userEmail = user.email
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign-In failed: \(error.localizedDescription)")
    }
}

extension AuthViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        // Fallback: create a new window if none is key.
        return UIWindow()
    }
}

// MARK: - Helpers

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

private func randomNonceString(length: Int = 32) -> String {
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    result.reserveCapacity(length)
    var remaining = length

    while remaining > 0 {
        var random: UInt8 = 0
        let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
        if status == errSecSuccess {
            let idx = Int(random) % charset.count
            result.append(charset[idx])
            remaining -= 1
        }
    }
    return result
}


// Change Auth states (if user Signed In or not)
extension Notification.Name {
    static let authDidSignIn  = Notification.Name("authDidSignIn")
    static let authDidSignOut = Notification.Name("authDidSignOut")
    static let sessionWillEnd = Notification.Name("sessionWillEnd")
}
