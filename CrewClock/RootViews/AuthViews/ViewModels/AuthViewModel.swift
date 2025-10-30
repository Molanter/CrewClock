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
    
    var auth = Auth.auth()
    
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
        } else {
            self.isSignedIn = false
        }
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            guard let self = self else { return }
            guard let user = user, error == nil else {
                print("⚠️ Google user not restored: \(error?.localizedDescription ?? "unknown error")")
                self.userToken = nil
                return
            }
            
            // IMPORTANT: refresh before reading the token
            user.refreshTokensIfNeeded { auth, err in
                if let err = err {
                    print("⚠️ Failed to refresh Google tokens: \(err.localizedDescription)")
                    self.userToken = nil
                    return
                }
                
                let token = user.accessToken.tokenString
                self.userToken = token
                print("🟢 Restored Google access token: \(token ?? "nil")")
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
                    if let user = authResult?.user {
                        self?.setProfile(user: user)
                    }
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
                self.setProfile(user: user)
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
    
    
    //MARK: Set profile data
    func setProfile(user: FirebaseAuth.User,
                    overrideName: String? = nil,
                    overridePhotoURL: URL? = nil) {
        
        // Prefer explicit overrides → Firebase top-level → provider data (google.com)
        let googleProfile = user.providerData.first { $0.providerID == "google.com" }
        
        let bestName =
        overrideName ??
        user.displayName ??
        googleProfile?.displayName ??
        "Someone"
        
        // Google photos often live here:
        var photo = overridePhotoURL?.absoluteString
        ?? user.photoURL?.absoluteString
        ?? googleProfile?.photoURL?.absoluteString
        ?? ""
        
        // (Optional) request a larger size if it’s a Google photo
        if photo.contains("googleusercontent.com") && !photo.contains("=s") {
            photo += "?sz=256"   // or "&sz=256" depending on the url
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
                    print("setProfile Firestore error: \(error.localizedDescription)")
                } else {
                    print("setProfile saved for \(bestName) - \(user.email ?? "") | photo: \(photo.isEmpty ? "none" : photo)")
                }
            }
    }
    
    //MARK: Sign Out :(
    func signOut() {
        // Capture before sign-out
        let uid = auth.currentUser?.uid
        let token  = app.fcmToken
        
        // Try to remove token mapping first (fire-and-forget is fine)
        if let uid, let token {
            let notificationsVM = NotificationsViewModel()
            notificationsVM.deleteFcmToken(userId: uid, token: token)
        }
        
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            
            // (Optional) also invalidate the device’s FCM token:
            // Messaging.messaging().deleteToken { error in
            //     if let error = error { print("deleteToken error:", error) }
            // }
            
            DispatchQueue.main.async {
                self.isSignedIn = false
                self.userName = nil
                self.userEmail = nil
                app.fcmToken = nil
            }
            
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
                    if let user = result?.user {
                        self.setProfile(user: user)
                        print("set profile called")
                    }
                    self.isSignedIn = true
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
