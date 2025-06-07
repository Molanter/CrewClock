//
//  SettingsTabView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/2/25.
//

import SwiftUI

struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Account")) {
                    NavigationLink("Profile Info", destination: Text("Profile Info View"))
                    Button("Sign Out") {
                        // TODO: Add sign-out logic
                    }
                }

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
}

#Preview {
    SettingsTabView()
}
