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
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var connectionsVM: ConnectionsViewModel

    
    var body: some View {
        Group {
            if authViewModel.isSignedIn {
                TabsView()
                    .onAppear {
                        logViewModel.fetchLogs()
                        projectViewModel.fetchProjects()
                        notificationsViewModel.fetchNotifications(completion: { array in notificationsViewModel.notifications = array })
                        userViewModel.fetchUser()
                        connectionsVM.fetchAllConnections()

                    }
            } else {
                SignInView()
            }
        }
        .id(authViewModel.isSignedIn) /// <- forces a clean rebuild on sign-in/out
    }
}


#Preview {
    RootView()
}
