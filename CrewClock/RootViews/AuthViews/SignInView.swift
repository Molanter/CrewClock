//
//  SignInView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/31/25.
//

import SwiftUI

struct SignInView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: AuthViewModel

    @FocusState private var focus: LoginField?
    
    @State private var email = ""
    @State private var password = ""
    @State private var emailEmpty = false
    @State private var passwordEmpty = false
    
    var body: some View {
        sheet
            .background {
                GlassBlur(removeAllFilters: true, blur: 0.1)
                    .cornerRadius(K.UI.cornerRadius)
                RoundedRectangle(cornerRadius: K.UI.cornerRadius, style: .continuous)
                    .stroke(colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3), lineWidth: 1.5)
            }
            .padding(.horizontal)
            .background {
                TwoCirclesBackground()
//                CarpetBackground()
            }
    }
    
    private var sheet: some View {
        VStack(spacing: K.UI.padding) {
            Text("Welcome!")
                .font(.title.bold())
                .padding(K.UI.padding)
            emailField
            passwordField
            mainButton
                .padding(.top, K.UI.padding)
            buttons
        }
        .padding(K.UI.padding*2)
    }
    
    private var emailField: some View {
        VStack {
            HStack {
                Text("Email")
                Spacer()
            }
            RoundedTextField(
                focus: $focus,
                text: $email,
                field: .loginEmail,
                promtText: "email@example.com",
                submitLabel: .next,
                onSubmit: { focus = .loginPass },
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                showRed: $emailEmpty
            )
        }
    }
    
    private var passwordField: some View {
        VStack {
            HStack {
                Text("Password")
                Spacer()
            }
            .padding(.top, K.UI.padding)
            RoundedTextField(
                focus: $focus,
                text: $password,
                field: .loginPass,
                promtText: "••••••••••••",
                submitLabel: .continue,
                onSubmit: {  },
                keyboardType: .emailAddress,
                textContentType: .password,
                showRed: $passwordEmpty
            )
        }
    }
    
    private var mainButton: some View {
        SignInButtonView(text: "SignIn", image: "", colored: true) {
            emailSignIn()
        }
    }
    
    private var buttons: some View {
        HStack(spacing: K.UI.padding) {
            SignInButtonView(text: "Apple", image: "apple.logo", colored: false) {
                viewModel.handleAppleSignIn()
            }
            SignInButtonView(text: "Google", image: "google.g.logo", colored: false) {
                viewModel.signInWithGoogle()
            }
        }
    }
    
    private func emailSignIn() {
        if !email.isEmpty, !password.isEmpty {
            self.emailEmpty = false
            self.passwordEmpty = false
            
            viewModel.signInWithEmail(email: email, password: password) { result in
                    switch result {
                    case .success(let user):
                        print("Signed in as \(user.email ?? "")")
                    case .failure(let error):
                        print("Error signing in: \(error.localizedDescription)")
                    }
                }
        }else if email.isEmpty {
            self.emailEmpty = true
        }else if password.isEmpty {
            self.passwordEmpty = true
        }
    }
}




#Preview {
    SignInView()
}
