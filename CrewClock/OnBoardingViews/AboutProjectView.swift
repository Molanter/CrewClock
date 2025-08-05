//
//  AboutProjectView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/5/25.
//


import SwiftUI

struct AppOverviewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("🚀 App Overview")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Description
                Text("CrewClock is a SwiftUI-powered time-tracking app created by a student developer at Bethel University. It’s built for contract workers and small teams who need a reliable way to record hours, organize projects, and collaborate in real time.")
                    .font(.body)
                    .lineSpacing(4)

                // Core Features Title
                Text("Core Features")
                    .font(.title2)
                    .fontWeight(.semibold)

                // Feature List
                VStack(alignment: .leading, spacing: 12) {
                    featureRow(icon: "⏱️", title: "Track time with a tap", description: "Start and stop timers with one tap, capturing precise start and end times for every shift.")
                    featureRow(icon: "📁", title: "Organize work by project", description: "Assign logs to named projects, customize each with its own color, and switch contexts instantly.")
                    featureRow(icon: "🗓️", title: "Visualize on a calendar", description: "View daily and weekly entries in an interactive calendar for better planning.")
                    featureRow(icon: "🤝", title: "Collaborate in real time", description: "Invite teammates and sync across devices instantly via Firebase.")
                    featureRow(icon: "🔔", title: "Stay informed", description: "Receive push notifications for new assignments and upcoming deadlines.")
                    featureRow(icon: "📶", title: "Work offline, sync later", description: "Logs cache locally and reconcile automatically once you’re back online.")
                }

                // Upcoming Features Title
                Text("Looking Ahead")
                    .font(.title2)
                    .fontWeight(.semibold)

                // Upcoming Features List
                VStack(alignment: .leading, spacing: 12) {
                    upcomingRow(icon: "📤", text: "Export logs to CSV/PDF for reporting and invoicing.")
                    upcomingRow(icon: "📊", text: "Analytics dashboard with interactive charts.")
                    upcomingRow(icon: "🔄", text: "Two-way calendar integration (import/export).")
                    upcomingRow(icon: "🤖", text: "Siri Shortcuts and Home Screen widgets.")
                    upcomingRow(icon: "⌚️", text: "Apple Watch companion for on-the-go tracking.")
                    upcomingRow(icon: "👥", text: "Advanced team management and task scheduling.")
                }
            }
            .padding()
            Section(footer: Text("Version 1.0.0")) {
                Text("CrewClock © 2025 Molanter")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
                .frame(height: 100)
        }
    }

    // MARK: - Helpers
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(icon)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func upcomingRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(icon)
                .font(.title3)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AppOverviewView()
}

