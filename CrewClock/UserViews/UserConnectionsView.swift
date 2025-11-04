//
//  UserConnectionsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/29/25.
//

import SwiftUI
import FirebaseAuth

struct UserConnectionsView: View {
    @EnvironmentObject private var connectionsVM: ConnectionsViewModel

    /// If nil → use the current authenticated user
    let viewingUid: String?

    // Map every relationship to: (other user's uid, status) relative to the viewing uid
    private func connectionItems(for me: String) -> [(uid: String, status: String)] {
        connectionsVM.connections.compactMap { conn -> (uid: String, status: String)? in
            guard let other = conn.uids.first(where: { $0 != me }) else { return nil }
            let status = conn.status.rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return (uid: other, status: status)
        }
    }

    var body: some View {
        Group {
            let me = viewingUid ?? Auth.auth().currentUser?.uid
            if let me, !connectionsVM.connections.isEmpty {
                List(connectionItems(for: me), id: \.uid) { item in
                    row(for: item.uid, status: item.status)
                }
                .listStyle(.insetGrouped)
            } else if let me {
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
                VStack(spacing: 12) {
                    Text("Not signed in")
                        .font(.headline)
                    Text("Sign in to view connections.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Connections")
        .onAppear {
            if let uid = viewingUid ?? Auth.auth().currentUser?.uid {
                connectionsVM.fetchAllConnections(for: uid)
            } else {
                connectionsVM.connections = []
            }
        }
    }

    @ViewBuilder
    private func row(for uid: String, status: String) -> some View {
        HStack(spacing: 12) {
            UserRowView(uid: uid)
            Spacer()

            if status == "accepted" {
                disconnectButton(for: uid)
            } else {
                Text(statusDisplay(status))
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(.systemGray5)))
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
        default:
            let c = raw.capitalized
            return c.isEmpty ? "Unknown" : c
        }
    }

    /// Uses current authenticated user’s authority to remove a connection with `uid`.
    @ViewBuilder
    private func disconnectButton(for uid: String) -> some View {
        Button(role: .destructive) {
            connectionsVM.removeConnection(uid)
            if let forUid = viewingUid ?? Auth.auth().currentUser?.uid {
                connectionsVM.fetchAllConnections(for: forUid)
            }
        } label: {
            Text("Disconnect")
        }
    }
}

#Preview {
    UserConnectionsView(viewingUid: nil)
        .environmentObject(ConnectionsViewModel())
        .environmentObject(UserViewModel())
}
