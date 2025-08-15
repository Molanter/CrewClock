//
//  UserConnectionsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/29/25.
//

import SwiftUI
import FirebaseAuth

struct UserConnectionsView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var connectionsVM: ConnectionsViewModel

    // Map every relationship to: (other user's uid, status)
    private var connectionItems: [(uid: String, status: String)] {
        let me = userViewModel.user?.uid ?? Auth.auth().currentUser?.uid
        guard let me else { return [] }

        return connectionsVM.connections.compactMap { conn in
            guard let other = conn.uids.first(where: { $0 != me }) else { return nil }
            let status = conn.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return (uid: other, status: status)
        }
    }

    var body: some View {
        Group {
            if connectionItems.isEmpty {
                VStack(spacing: 12) {
                    Text("No connections yet")
                        .font(.headline)
                    Text("When you connect with others, they’ll show up here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .multilineTextAlignment(.center)
            } else {
                List(connectionItems, id: \.uid) { item in
                    row(for: item.uid, status: item.status)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Connections")
        .onAppear {
            connectionsVM.fetchAllConnections()
        }
    }

    @ViewBuilder
    private func row(for uid: String, status: String) -> some View {
        HStack(spacing: 12) {
            UserRowView(uid: uid)
            Spacer()

            // Status / Actions
            if status == "accepted" {
                disconnectButton(for: uid)
            } else {
                // Show a simple status tag for non-accepted states
                Text(statusDisplay(status))
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray5))
                    )
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }

    private func statusDisplay(_ raw: String) -> String {
        switch raw {
        case "pending":  return "Pending"
        case "declined": return "Declined"
        case "removed":  return "Removed"
        default:         return raw.capitalized.isEmpty ? "Unknown" : raw.capitalized
        }
    }

    @ViewBuilder
    private func disconnectButton(for uid: String) -> some View {
        Button(role: .destructive) {
            disconnect(uid)
        } label: {
            Text("Disconnect")
        }
    }

    private func disconnect(_ uid: String) {
        connectionsVM.removeConnection(uid)
        connectionsVM.fetchAllConnections()
    }
}

#Preview {
    UserConnectionsView()
        .environmentObject(UserViewModel())
        .environmentObject(ConnectionsViewModel())
}
