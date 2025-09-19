//
//  NotificationRowView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/25/25.
//

import SwiftUI
import FirebaseAuth

struct NotificationRowView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var connectionsVM: ConnectionsViewModel
    @EnvironmentObject private var projectViewModel: ProjectViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel

    let notification: NotificationFB
    var auth = Auth.auth()
    
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: notification.timestamp)
    }
    
    var body: some View {
        row
            .onAppear {
                appear()
            }
    }
    
    private var row: some View {
        VStack {
            VStack {
                header
                message
            }
            if notification.type != .connectionAccepted && notification.type != .commentMention && notification.type != .scheduleUpdate {
                buttons
            }
        }
        .padding(K.UI.padding*2)
        .background {
            RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                .fill(Color(.listRow))
        }
    }
    
    private var header: some View {
        HStack {
            if let user = getUser(notification.fromUID) {
                UserProfileImage(user.profileImage)
                    .frame(width: 25)
                Text(user.name).bold()
            } else {
                Text(notification.type.message).bold()
            }
            Spacer()
            Text(formattedTimestamp)
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }
    
    private var message: some View {
        Text(notification.message)
            .font(.body)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var buttons: some View {
        HStack(alignment: .center, spacing: 10) {
            secondaryButton
            mainButton
        }
    }
    
    private var secondaryButton: some View {
        Button {
            secondAction(notification.type)
        } label: {
            Text("Reject")
                .padding(K.UI.padding)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                        .fill(Color.red)
                }
        }
        .buttonStyle(.plain)
    }
    
    private var mainButton: some View {
        Button {
            mainAction(notification.type)
        } label: {
            Text("Connect")
                .padding(K.UI.padding)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                        .fill(K.Colors.accent)
                }
        }
        .buttonStyle(.plain)
    }
    
    private func appear() {
        userViewModel.fetchUser(by: notification.fromUID)
    }
    
    private func getUser(_ uid: String) -> UserFB? {
        userViewModel.getUser(uid)
    }
    
    private func mainAction(_ type: NotificationType) {
        if notification.status != .completed, notification.status != .cancelled {
            switch type {
            case .connectInvite:
                connectFunc()
            case .projectInvite:
                projectViewModel.addCrewMember(documentId: notification.relatedId, crewMember: notification.relatedId)
                notificationsViewModel.updateNotificationStatus(notificationId: notification.notificationId, newStatus: .accepted) { bool in}
            case .taskAssigned:
                return
            case .commentMention:
                return
            case .scheduleUpdate:
                return
            case .connectionAccepted:
                return
            case .test:
                return
            case .teamInite:
                return
            }
        }
    }
    
    private func secondAction(_ type: NotificationType) {
        if notification.status != .completed, notification.status != .cancelled {
            switch type {
            case .connectInvite:
                notificationsViewModel.updateNotificationStatus(notificationId: notification.notificationId, newStatus: .rejected) { bool in}
            case .projectInvite:
                notificationsViewModel.updateNotificationStatus(notificationId: notification.notificationId, newStatus: .rejected) { bool in}
            case .taskAssigned:
                notificationsViewModel.updateNotificationStatus(notificationId: notification.notificationId, newStatus: .rejected) { bool in}
            case .commentMention:
                return
            case .scheduleUpdate:
                return
            case .connectionAccepted:
                return
            case .test:
                return
            case .teamInite:
                return
            }
        }
        }
    
    private func connectFunc() {
        connectionsVM.acceptConnection(from: notification.fromUID, notificationId: notification.notificationId)
        notificationsViewModel.updateNotificationStatus(notificationId: notification.notificationId, newStatus: .accepted) { bool in}
    }

}

#Preview {
    NotificationRowView(notification: NotificationFB(
        data: [
            "title": "Test User",
            "message": "Wants to connect on CrewClock. Press Connect to accept or Reject.",
            "timestamp": Date(),
            "recipientUID": ["test-uid"],
            "fromUID": "from-uid",
            "isRead": false,
            "status": "received",
            "type": "connectInvite",
            "relatedId": "1234"
        ],
        documentId: "notif-test-1234"
    ))
    .environmentObject(UserViewModel())
}
