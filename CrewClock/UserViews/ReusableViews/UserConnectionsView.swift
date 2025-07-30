//
//  UserConnectionsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/29/25.
//

import SwiftUI

struct UserConnectionsView: View {
    @EnvironmentObject private var userViewModel: UserViewModel

    var uids: [String] {
        return userViewModel.user?.connections ?? []
    }

    var body: some View {
        list
            .navigationTitle("Connections")
    }
    
    private var list: some View {
        List(uids, id: \.self) { uid in
            row(for: uid)
        }
    }
    
    @ViewBuilder
    private func row(for uid: String) -> some View {
        HStack {
            UserRowView(uid: uid)
            Spacer()
            dissconnectButton(for: uid)
        }
    }
    
    @ViewBuilder
    private func dissconnectButton(for uid: String) -> some View {
        Button {
            disconnect(uid)
        } label: {
            Text("Disconnect")
                .foregroundStyle(.red)
        }
    }
    
    private func disconnect(_ uid: String) {
        userViewModel.removeConnection(uid)
    }
}

#Preview {
    UserConnectionsView()
        .environmentObject(UserViewModel())
}
