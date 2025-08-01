//
//  CrewClockTestSignInView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/27/25.
//

import SwiftUI

struct TestSignInView: View {
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
                .cornerRadius(K.UI.cornerRadius)
            }
            .padding(.horizontal)
        }
    }
}


#Preview {
    TestSignInView()
}
