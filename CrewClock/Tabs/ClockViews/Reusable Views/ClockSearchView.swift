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
    @EnvironmentObject var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject var publishedVars: PublishedVariebles
    
    private var auth = Auth.auth()
    
    @State private var notificationUID: String? = nil
    @State private var sentInvites: Set<String> = []
    
    var body: some View {
        if !publishedVars.searchClock.isEmpty, !publishedVars.searchClock.isEmpty{
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
    
    private var list: some View {
        List(searchUserViewModel.foundUIDs, id: \.self) { uid in
            row(uid)
        }
    }
    
    @ViewBuilder
    private func row(_ uid: String) -> some View {
        HStack(alignment: .center) {
            UserRowView(uid: uid)
            Spacer()
            if userViewModel.user?.connections.contains(uid) == true {
                Text("Connected")
                    .foregroundStyle(.green)
            } else if sentInvites.contains(uid) {
                Text("Sent")
                    .foregroundStyle(.gray)
            } else {
                Button {
                    self.connectWithPerson(uid)
                } label: {
                    Text("Connect")
                        .foregroundStyle(.indigo)
                }
                .buttonStyle(.plain)
            }
        }
//        .popover(
//            present: .init(
//                get: { notificationUID == uid },
//                set: { newValue in
//                    if !newValue { notificationUID = nil }
//                }
//            ),
//            attributes: {
//                $0.sourceFrameInset = .zero
//                $0.position = .absolute(originAnchor: .top, popoverAnchor: .top)
//                $0.presentation.animation = .spring()
//                $0.presentation.transition = .move(edge: .top)
//                $0.dismissal.mode = .tapOutside
//                $0.dismissal.dragDismissalProximity = 80
//            },
//            view: {
//                HStack(spacing: 12) {
//                    Image(systemName: "person.2.badge.plus")
//                    Text("Invite to connect sent.")
//                        .font(.headline)
//                    Spacer()
//                }
//                .padding()
//                .background(Color.listRow)
//                .cornerRadius(12)
//                .frame(maxWidth: .infinity)
//            }
//        )
    }
    
    private func connectWithPerson(_ uid: String) {
        sentInvites.insert(uid)
        self.notificationUID = uid
        
        let newNotification = NotificationModel(
            title: "Do you whant to connect?",
            message: "\(userViewModel.user?.name ?? auth.currentUser?.displayName ?? "Someone") sent a connection invite. Respond to it in the app.",
            timestamp: Date(),
            recipientUID: [uid],
            fromUID: userViewModel.user?.uid ?? auth.currentUser?.uid ?? "",
            isRead: false,
            type: .connectInvite,
            relatedId: uid
        )
        
        notificationsViewModel.getFcmByUid(uid: uid, notification: newNotification)
    }
}

//#Preview {
//    ClockSearchView()
//}
