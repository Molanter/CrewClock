//
//  UserConnectionsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/29/25.
//

import SwiftUI
import FirebaseAuth

private extension ConnectionStatus {
    var display: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .rejected: return "Rejected"
        case .blocked: return "Blocked"
        }
    }
}

private struct ConnectionItem: Identifiable, Hashable, Equatable {
    let uid: String
    let status: ConnectionStatus
    var id: String { uid }
}

struct UserConnectionsView: View {
    @EnvironmentObject private var connectionsVM: ConnectionsViewModel

    /// If nil → use the current authenticated user
    let viewingUid: String?

    @State private var showConfirmDisconnectStep1 = false
    @State private var showConfirmDisconnectStep2 = false
    @State private var pendingDisconnectUid: String? = nil

    private var currentUid: String? { viewingUid ?? Auth.auth().currentUser?.uid }

    // Map every relationship to a strongly-typed item
    private func connectionItems(for me: String) -> [ConnectionItem] {
        connectionsVM.connections.compactMap { conn -> ConnectionItem? in
            guard let other = conn.uids.first(where: { $0 != me }) else { return nil }
            return ConnectionItem(uid: other, status: conn.status)
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let me = currentUid, !connectionsVM.connections.isEmpty {
                connectionsList(for: me)
            } else if currentUid != nil {
                emptyState
            } else {
                notSignedInState
            }
        }
        .confirmationDialog(disconnectStep1Title, isPresented: $showConfirmDisconnectStep1, titleVisibility: .visible) {
            confirmDisconnectButtons
        } message: {
            Text(disconnectStep1Message)
        }
        .alert(disconnectStep2Title, isPresented: $showConfirmDisconnectStep2) {
            finalDisconnectButtons
        } message: {
            Text(disconnectStep2Message)
        }
        .navigationTitle("Connections")
        .onAppear(perform: loadConnections)
    }

    // MARK: - Subviews

    /// List of user connections
    private func connectionsList(for me: String) -> some View {
        let items = connectionItems(for: me)
        return List(items) { item in
            row(for: item)
        }
        .listStyle(.insetGrouped)
    }

    /// State shown when no connections exist
    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No connections yet")
                .font(.headline)
            Text("When you connect with others, they’ll show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
    }

    /// State shown when user is not signed in
    private var notSignedInState: some View {
        VStack(spacing: 12) {
            Text("Not signed in")
                .font(.headline)
            Text("Sign in to view connections.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Step 1 confirmation dialog title and message
    private var disconnectStep1Title: String { "Disconnect from this user?" }
    private var disconnectStep1Message: String { "You can reconnect later, but this will remove the connection now." }

    /// Step 2 alert title and message
    private var disconnectStep2Title: String { "Are you absolutely sure?" }
    private var disconnectStep2Message: String { "This action will immediately remove the connection." }

    /// First confirmation dialog buttons
    private var confirmDisconnectButtons: some View {
        Group {
            Button("Disconnect", role: .destructive) {
                showConfirmDisconnectStep1 = false
                showConfirmDisconnectStep2 = true
            }
            Button("Cancel", role: .cancel) { showConfirmDisconnectStep1 = false }
        }
    }

    /// Final alert buttons for double-confirm disconnect
    private var finalDisconnectButtons: some View {
        Group {
            Button("Yes, disconnect", role: .destructive) {
                if let uid = pendingDisconnectUid {
                    connectionsVM.removeConnection(uid)
                    if let forUid = viewingUid ?? Auth.auth().currentUser?.uid {
                        connectionsVM.fetchAllConnections(for: forUid)
                    }
                }
                pendingDisconnectUid = nil
            }
            Button("Cancel", role: .cancel) { pendingDisconnectUid = nil }
        }
    }

    /// Loads all connections for the current user
    private func loadConnections() {
        if let uid = currentUid {
            connectionsVM.fetchAllConnections(for: uid)
        } else {
            connectionsVM.connections = []
        }
    }

    @ViewBuilder
    private func row(for item: ConnectionItem) -> some View {
        HStack(spacing: 12) {
            UserRowView(uid: item.uid)
            Spacer()
            if item.status == .accepted {
                disconnectButton(for: item.uid)
            } else {
                StatusChip(text: item.status.display)
            }
        }
        .contentShape(Rectangle())
    }

    /// Uses current authenticated user’s authority to remove a connection with `uid`.
    @ViewBuilder
    private func disconnectButton(for uid: String) -> some View {
        Button(role: .destructive) {
            pendingDisconnectUid = uid
            showConfirmDisconnectStep1 = true
        } label: {
            Text("Disconnect")
        }
    }
}

private struct StatusChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(.systemGray5)))
            .foregroundStyle(.secondary)
    }
}

#Preview {
    UserConnectionsView(viewingUid: nil)
        .environmentObject(ConnectionsViewModel())
        .environmentObject(UserViewModel())
}
