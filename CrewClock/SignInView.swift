//
//  CrewClockSignInView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/27/25.
//

import SwiftUI

struct CrewClockSignInView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to CrewClock")
                .font(.largeTitle)
                .bold()

            if viewModel.isSignedIn {
                VStack(spacing: 10) {
                    Text("✅ Signed in!")
                        .font(.title2)
                        .foregroundColor(.green)

                    if let name = viewModel.userName {
                        Text("Name: \(name)")
                    }
                    if let email = viewModel.userEmail {
                        Text("Email: \(email)")
                    }
                    Button("Log Out") {
                        viewModel.signOut()
                    }
                    .padding(.top)
                    .foregroundColor(.red)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                Button(action: {
                    viewModel.signInWithGoogle()
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text("Sign in with Google")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
            }
        }
        .padding()
    }
}


#Preview {
    CrewClockSignInView()
}
