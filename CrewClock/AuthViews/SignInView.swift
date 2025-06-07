//
//  CrewClockSignInView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/27/25.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to CrewClock")
                .font(.largeTitle)
                .bold()

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
            .padding(.horizontal)
        }
    }
}


#Preview {
    SignInView()
}
