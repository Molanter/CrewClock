//
//  RootView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/28/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var logViewModel: LogsViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    
    var body: some View {
        if authViewModel.isSignedIn {
            TabsView()
                .onAppear {
                    authViewModel.setProfile()
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
