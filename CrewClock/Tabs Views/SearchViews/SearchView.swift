//
//  SearchView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/20/25.
//

import SwiftUI
import Popovers
import FirebaseAuth

struct SearchView: View {
    @EnvironmentObject var searchUserViewModel: SearchUserViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject private var connectionsVM: ConnectionsViewModel
    @EnvironmentObject var publishedVars: PublishedVariebles
    
    private var auth = Auth.auth()
    
    @State private var notificationUID: String? = nil
    @State private var sentInvites: Set<String> = []
    
    var body: some View {
        ZStack(alignment: .bottom) {
            switchView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background {
//            ListBackground()
//                .ignoresSafeArea()
//        }
    }
    
    private var switchView: some View {
        Group {
            if !publishedVars.searchClock.isEmpty {
                list
            }else if searchUserViewModel.foundUIDs.isEmpty, !publishedVars.searchClock.isEmpty {
                VStack {
                    Spacer()
                    NoContentView(contentType: .noUsers)
                }
            }else {
                VStack {
                    Spacer()
                    NoContentView(contentType: .search)
                    Spacer()
                }
            }
        }
    }
    
    private var list: some View {
        GlassList {
            ForEach(searchUserViewModel.foundUIDs, id: \.self) { uid in
                row(uid)
            }
        }
    }
    
    @ViewBuilder
    private func row(_ uid: String) -> some View {
        HStack(alignment: .center) {
            UserRowView(uid: uid)
            Spacer()
            if let connection = connectionsVM.connections.first(where: { $0.uids.contains(uid) }) {
                Text(connection.status.rawValue.capitalized)
                    .foregroundStyle(statusCapsule(status: connection.status))
                    .font(.caption)
                    .padding(5)
                    .background(
                        Capsule().fill(statusCapsule(status: connection.status).opacity(0.5))
                    )
            }
        }
    }
    
    private func connectWithPerson(_ uid: String) {
        sentInvites.insert(uid)
        self.notificationUID = uid
        connectionsVM.connectWithPerson(uid)
    }
    
    private func statusCapsule(status: ConnectionStatus) -> Color {
        return status == .pending ? .gray :
        status == .accepted ? .green :
        status == .rejected ? .red :
        .orange
}
}

//#Preview {
//    ClockSearchView()
//}
