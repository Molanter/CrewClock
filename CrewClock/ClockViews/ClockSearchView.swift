//
//  ClockSearchView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/20/25.
//

import SwiftUI
import Popovers
import FirebaseAuth

struct ClockSearchView: View {
    @EnvironmentObject var searchUserViewModel: SearchUserViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject private var connectionsVM: ConnectionsViewModel
    @EnvironmentObject var publishedVars: PublishedVariebles
    
    private var auth = Auth.auth()
    
    @State private var notificationUID: String? = nil
    @State private var sentInvites: Set<String> = []
    
    var body: some View {
        ZStack(alignment: .bottom) {
//            if publishedVars.tabSelected == 0 || publishedVars.tabSelected == 1 {
//                WorkingFooterView()
//                    .padding(.horizontal, K.UI.padding*2)
//            }
            switchView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ListBackground()
                .ignoresSafeArea()
        }
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
            if userViewModel.user?.connections.contains(uid) == true {
                Text("Connected")
                    .foregroundStyle(.secondary)
            } else if sentInvites.contains(uid) {
                Text("Sent")
                    .foregroundStyle(.gray)
            } else {
                Button {
                    self.connectWithPerson(uid)
                } label: {
                    Text("Connect")
                        .foregroundStyle(K.Colors.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func connectWithPerson(_ uid: String) {
        sentInvites.insert(uid)
        self.notificationUID = uid
        connectionsVM.connectWithPerson(uid)
    }
}

//#Preview {
//    ClockSearchView()
//}
