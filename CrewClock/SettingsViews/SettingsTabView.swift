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
    
    private let user = Auth.auth().currentUser
    
    var body: some View {
        NavigationStack {
            List {
                profileHeaderSection

                connectionsSection
                
                Section(header: Text("Time Tracking")) {
                    NavigationLink("Preferences", destination: Text("Time Tracking Preferences View"))
                }

                Section(header: Text("Google Spreadsheet")) {
                    NavigationLink("Linked Spreadsheet", destination: Text("Spreadsheet Settings View"))
                }

                Section(header: Text("Notifications")) {
                    NavigationLink("Notification Settings", destination: Text("Notification Settings View"))
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
            }
            .navigationTitle("Settings")
        }
    }
    
    private var profileHeaderSection: some View {
        Section(header: Text("Account")) {
            if let user = user {
                HStack(spacing: 10) {
                        profilePicture(user)
                    VStack(alignment: .leading) {
                        Text(user.displayName!)
                        Text(user.email!)
                    }
                }
                .padding(.vertical)
            }
            NavigationLink("Profile Info", destination: UserRowView(uid: "v51yL1dwlQWFCAGfMWPuvpVUUXl1"))
        }
    }
    
    private var connectionsSection: some View {
        HStack(spacing: 15) {
            if let connections = userViewModel.user?.connections.count {
                SettingRoundedButton(image: false, text1: "Connections", text2: connections.description)
            }
                SettingRoundedButton(image: true, text1: "rectangle.portrait.and.arrow.right", text2: "Sign Out")
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    
    private func profilePicture(_ user: User) -> some View {
        AsyncImage(url: user.photoURL) { phase in
                switch phase {
                case .empty:
                    ProgressView() // While loading
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    Image(systemName: "person.crop.circle.dashed")
                @unknown default:
                    EmptyView()
                }
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 50)
            .cornerRadius(.infinity)
    }
}
//
//#Preview {
//    SettingsTabView()
//}
