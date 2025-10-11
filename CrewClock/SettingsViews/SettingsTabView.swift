//
//  SettingsTabView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/2/25.
//

import SwiftUI
import FirebaseAuth

struct SettingsTabView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var connectionsVM: ConnectionsViewModel
    
    @StateObject private var membershipVM = TeamMembershipCheckerViewModel()
    
    private let sections = SettingsNavigationLinks.allCases.groupedAndSorted()

    var body: some View {
        NavigationStack {
            listView
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        NotificationsView()
                            .hideTabBarWhileActive("notifications")
                    }label: {
                        Image(systemName: "bell")
                    }
                }
            }
            .onAppear {membershipVM.refresh()}
            .onDisappear {membershipVM.stopListening()}
        }
    }
    
    private var listView: some View {
        GlassList {
            profileHeaderSection
            headerScroll
                .listSectionSpacing(10)
            
            ForEach(sections, id: \.0) { section, items in
                Section(section.rawValue) {
                    ForEach(items) { item in
                        SettingNavigationLinkView(type: item)
                    }
                }
            }
            
            Section(footer: Text("Version 1.0.0")) {
                Text("CrewClock © 2025 Molanter")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Spacer()
                    .frame(height: 50)
                    .listRowBackground(Color.clear)
            }
        }
    }
    
    ///Header current user info and NavigationLink to profile View
    private var profileHeaderSection: some View {
        Section(header: Text("Account")) {
            if let user = userViewModel.user {
                HStack(spacing: 10) {
                    profilePicture(user)
                    VStack(alignment: .leading) {
                        Text(userViewModel.user?.name ?? "Someone")
                        Text(userViewModel.user?.email ?? "examle@gmail.com")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical)
                NavigationLink("Profile Info", destination: UserRowView(uid: user.uid))
            }
        }
    }
    
    //MARK: Header Scroll
    ///Header Scroll with buttons
    private var headerScroll: some View {
        Section {
            ScrollView(.horizontal) {
                HStack(spacing: 15) {
                    connections
                    pushNotification
                    signOut
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
    
    ///Connections NavigationLink
    private var connections: some View {
        NavigationLink {
            UserConnectionsView()
                .hideTabBarWhileActive("myLogs")
        } label: {
            let count = connectionsVM.connections.filter { $0.status == "accepted" }.count
            SettingRoundedButton(image: false, text1: "Connections", text2: count.description)
        }
        .buttonStyle(.plain)
    }
    
    ///Send push notification to this User
    private var pushNotification: some View {
        Button {
            if let uid = userViewModel.user?.uid {
                print("press worked")
                self.sendPushTo(uid)
            }
        }label: {
            SettingRoundedButton(image: true, text1: "bell.badge", text2: "Send Push")
        }
        .buttonStyle(.plain)
    }
    
    ///Sign Out button
    private var signOut: some View {
        Button {
            authViewModel.signOut()
        } label: {
                SettingRoundedButton(image: true, text1: "rectangle.portrait.and.arrow.forward", text2: "Sign Out")
                .foregroundStyle(Color.red)
        }
        .buttonStyle(.plain)
    }
    
    
    //MARK: Functions
    ///returns circle profile picture
    private func profilePicture(_ user: UserFB) -> some View {
        UserProfileImageCircle(user.profileImage)
            .aspectRatio(contentMode: .fill)
            .frame(width: 50, height: 50)
            .cornerRadius(.infinity)
    }
    
    ///Sends Push
    private func sendPushTo(_ uid: String) {
        let user = Auth.auth().currentUser
        let newNotification = NotificationModel(
            title: "Test Push Notification",
            message: "Hi \(userViewModel.user?.name ?? user?.displayName ?? "Someone"), it is test of push notification!",
            timestamp: Date(),
            recipientUID: [uid],
            fromUID: userViewModel.user?.uid ?? user?.uid ?? "",
            isRead: false,
            type: .test,
            relatedId: uid
        )
        
        notificationsViewModel.getFcmByUid(uid: uid, notification: newNotification)
    }
}

//
//#Preview {
//    SettingsTabView()
//}
