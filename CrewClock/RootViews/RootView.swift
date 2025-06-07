//
//  RootView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/28/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var logViewModel = LogsViewModel()
    @StateObject private var projectViewModel = ProjectViewModel()
    
    var body: some View {
        if authViewModel.isSignedIn {
            TabsView()
                .onAppear {
                    logViewModel.fetchLogs()
                    projectViewModel.fetchProjects()
                }
        } else {
            SignInView()
        }
    }
}


#Preview {
    RootView()
}
