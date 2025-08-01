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
    @EnvironmentObject var publishedVars: PublishedVariebles
    @EnvironmentObject var notificationsViewModel: NotificationsViewModel


    private let user = Auth.auth().currentUser
    
    var body: some View {
        NavigationStack {
            List {
                profileHeaderSection

                headerScroll
                
                Section(header: Text("Time Tracking")) {
                    NavigationLink("Preferences", destination: Text("Time Tracking Preferences View"))
                }

                Section(header: Text("Google Spreadsheet")) {
                    NavigationLink("Linked Spreadsheet", destination: Text("Spreadsheet Settings View"))
                }

                Section(header: Text("Notifications")) {
                    NavigationLink("Notification Settings", destination: NotificationsView())
                }

                Section(header: Text("Appearance")) {
                    NavigationLink {
                        Text("Appearance Settings View")
                    } label: {
                        Text("Theme & Font")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Section(header: Text("Help & Support")) {
                    NavigationLink("FAQ", destination: Text("FAQ View"))
                    NavigationLink("Contact Support", destination: Text("Contact Support View"))
                    NavigationLink("Report a Bug", destination: Text("Report a Bug View"))
                }

                Section(header: Text("Privacy & Data")) {
                    NavigationLink("Export My Logs", destination: Text("Export Logs View"))
                    NavigationLink("Delete My Account", destination: Text("Delete Account View"))
                }

                Section(header: Text("Advanced")) {
                    NavigationLink("Re-authenticate Google", destination: Text("Re-auth View"))
                    NavigationLink("Reset App Settings", destination: Text("Reset Settings View"))
                }
                Section {
                    Spacer()
                        .frame(height: 50)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    ///Header current user info and NavigationLink to profile View
    private var profileHeaderSection: some View {
        Section(header: Text("Account")) {
            if let user = user {
                HStack(spacing: 10) {
                        profilePicture(user)
                    VStack(alignment: .leading) {
                        Text(user.displayName ?? "Someone")
                        Text(user.email!)
                    }
                }
                .padding(.vertical)
            }
            NavigationLink("Profile Info", destination: UserRowView(uid: "v51yL1dwlQWFCAGfMWPuvpVUUXl1"))
        }
    }
    
    ///Header Scroll with buttons
    private var headerScroll: some View {
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
    
    //MARK: Header Scroll
    ///Connections NavigationLink
    private var connections: some View {
        NavigationLink {
            UserConnectionsView()
//                    .searchable(text: $publishedVars.userSearch)
        } label: {
            if let connections = userViewModel.user?.connections.count {
                SettingRoundedButton(image: false, text1: "Connections", text2: connections.description)
            }
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
    private func profilePicture(_ user: User) -> some View {
        UserProfileImage(user.photoURL?.absoluteString ?? "")
            .aspectRatio(contentMode: .fit)
            .frame(width: 50)
            .cornerRadius(.infinity)
    }
    
    ///Sends Push
    private func sendPushTo(_ uid: String) {
        let newNotification = NotificationModel(
            title: "Test Push Notification",
            message: "Hi \(userViewModel.user?.name ?? user?.displayName ?? "Someone"), it is test of push notification!",
            timestamp: Date(),
            recipientUID: [uid],
            fromUID: userViewModel.user?.uid ?? user?.uid ?? "",
            isRead: false,
            type: .connectInvite,
            relatedId: uid
        )
        
        notificationsViewModel.getFcmByUid(uid: uid, notification: newNotification)
    }
}

//
//#Preview {
//    SettingsTabView()
//}
