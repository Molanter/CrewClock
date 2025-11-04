//
//  RootView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/28/25.
//

import SwiftUI
import FirebaseAuth


private enum SessionPhase { case signedIn, tearingDown, signedOut }

struct RootView: View {
    @StateObject private var profileCheckVM = ProfileCompletenessViewModel()
    @State private var showProfileGate = false

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var logsVM: LogsViewModel
    @EnvironmentObject var projectsVM: ProjectViewModel
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @EnvironmentObject var connectionsVM: ConnectionsViewModel
    
    @State private var deviceShaked = false
    @State private var phase: SessionPhase = (Auth.auth().currentUser != nil) ? .signedIn : .signedOut
    var body: some View {
        Group {
            switch phase {
            case .signedIn:
                TabsView()
            case .tearingDown:
                // Blank screen for one runloop while VMs quiesce
                Color.clear
                    .ignoresSafeArea()
                    .onAppear {
                        // one more tick, then flip to signedOut
                        DispatchQueue.main.async {
                            phase = .signedOut
                        }
                    }
            case .signedOut:
                SignInView()
            }
        }
        // Run once per sign-in state change. Sync fetches only.
        .task {
            if  phase == .signedIn {
                logsVM.fetchLogs()
                projectsVM.fetchProjects()
                notificationsVM.fetchNotifications { array in
                    notificationsVM.notifications = array
                }
                userVM.fetchUser()
                connectionsVM.fetchAllConnections()
                profileCheckVM.evaluate(with: userVM.user)
            }
        }
        // Drive phase by notifications, not by @Published flips
        .onReceive(NotificationCenter.default.publisher(for: .authDidSignIn)) { _ in
            withTransaction(Transaction(animation: nil)) { phase = .signedIn }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionWillEnd)) { _ in
            withTransaction(Transaction(animation: nil)) { phase = .tearingDown }
        }
        .onReceive(userVM.$user.dropFirst()) { newUser in
            profileCheckVM.evaluate(with: newUser)
            showProfileGate = profileCheckVM.isIncomplete
        }
        .onReceive(NotificationCenter.default.publisher(for: .authDidSignOut)) { _ in
            // no-op; we already moved to .signedOut after teardown
        }
        // Disable animations during auth transitions to avoid graph cycles
        .transaction { $0.disablesAnimations = true }
        .onShake { deviceShaked.toggle() }
        .sheet(isPresented: $deviceShaked) {
            ReportBugView().presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showProfileGate) {
            NavigationStack {
                ProfileEditView(isFinishingProfile: true)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { showProfileGate = false }
                        }
                    }
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
        .environmentObject(LogsViewModel())
        .environmentObject(ProjectViewModel())
        .environmentObject(UserViewModel())
        .environmentObject(NotificationsViewModel())
        .environmentObject(ConnectionsViewModel())
}
