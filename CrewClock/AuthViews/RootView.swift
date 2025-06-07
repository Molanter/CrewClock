//
//  RootView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/28/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        if authViewModel.isSignedIn {
            LoggedInView()
                .environmentObject(authViewModel)
        } else {
            SignInView()
                .environmentObject(authViewModel)
        }
    }
}


#Preview {
    RootView()
}
