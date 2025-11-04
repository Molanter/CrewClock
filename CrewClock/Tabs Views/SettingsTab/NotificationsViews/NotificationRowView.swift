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

    @StateObject private var invitesVM = TeamInvitesViewModel()
    @StateObject private var teamsVM = MyTeamsViewModel()
    @StateObject private var taskVM = TaskViewModel()

    private struct TaskRoute: Identifiable, Hashable { let id: String }
    @State private var taskToOpen: TaskRoute?
    
    let notification: NotificationFB
    var auth = Auth.auth()
    private let manager = FirestoreManager()
    
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
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    notificationsViewModel.deleteNotification(documentId: notification.id)
                }label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
            }
            .navigationDestination(item: $taskToOpen) { route in
                TaskDetailView(taskId: route.id)
            }
    }
    
    private var leftSection: some View {
        VStack {
            profilePicture
            Rectangle()
                .foregroundStyle(.secondary)
                .frame(width: 1)
                .frame(maxHeight: .infinity)
//                .padding()
        }
    }
    
    private var row: some View {
        HStack(alignment: .center, spacing: 10) {
            leftSection
            rightPart
        }
        .padding(K.UI.padding)
        .background {
            RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                .fill(Color(.listRow))
        }
    }
    
    private var rightPart: some View {
        VStack {
            VStack(alignment: .leading, spacing: 10) {
                header
                message
            }
            let hideButtons: Bool = [.connectionAccepted, .commentMention, .scheduleUpdate, .test, .taskUpdated].contains(notification.type)
            if !hideButtons { buttons }
        }
    }
    
    private var header: some View {
        HStack {
            if let user = getUser(notification.fromUID) {
                Text(user.name).bold()
            } else {
                Text(notification.type.message).bold()
            }
            Spacer()
            Text(formattedTimestamp)
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .padding(.top, 7)
    }
    
    private var profilePicture: some View {
        Group {
            if let user = getUser(notification.fromUID), !user.profileImage.isEmpty {
                UserProfileImageCircle(user.profileImage)
                    .frame(width: 25, height: 25)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(.secondary)
            }
        }
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
            Text("Reject").foregroundStyle(.white)
                .padding(K.UI.padding/2)
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
            Text(notification.type.mainAction).foregroundStyle(.white)
                .padding(K.UI.padding/2)
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
        return userViewModel.getUser(uid)
        
    }
    
    private func mainAction(_ type: NotificationType) {
        if notification.status != .completed, notification.status != .cancelled {
            switch type {
            case .connectInvite:
                connectFunc()
            case .projectInvite:
                if let uid = auth.currentUser?.uid {
                    projectViewModel.addCrewMember(documentId: notification.relatedId, crewMember: uid)
                    notificationsViewModel.updateNotificationStatus(notificationId: notification.id, newStatus: .accepted) { _ in }
                }
            case .taskAssigned:
                Task {
                    do {
                        _ = try await manager.upsert(
                            ["status": "accepted"],
                            at: FSPath.Task(id: notification.relatedId),
                            merge: true
                        )
                        notificationsViewModel.updateNotificationStatus(notificationId: notification.id, newStatus: .accepted) { _ in }
                    } catch {
                        print("Failed to accept task and notify: \(error)")
                    }
                }
            case .commentMention:
                return
            case .scheduleUpdate:
                return
            case .connectionAccepted:
                return
            case .test:
                return
            case .teamInvite:
                Task { await invitesVM.acceptInvite(teamId: notification.relatedId) }
            case .taskUpdated:
                self.taskToOpen = TaskRoute(id: notification.relatedId)
            }
        }
    }
    
    private func secondAction(_ type: NotificationType) {
        if notification.status != .completed, notification.status != .cancelled {
            switch type {
            case .connectInvite:
                notificationsViewModel.updateNotificationStatus(notificationId: notification.id, newStatus: .rejected) { bool in}
            case .projectInvite:
                notificationsViewModel.updateNotificationStatus(notificationId: notification.id, newStatus: .rejected) { bool in}
            case .taskAssigned:
                Task {
                    do {
                        _ = try await manager.upsert(
                            ["status": "rejected"],
                            at: FSPath.Task(id: notification.relatedId),
                            merge: true
                        )
                        notificationsViewModel.updateNotificationStatus(notificationId: notification.id, newStatus: .rejected) { _ in }
                    } catch {
                        print("Failed to reject task and notify: \(error)")
                    }
                }
            case .commentMention:
                return
            case .scheduleUpdate:
                return
            case .connectionAccepted:
                return
            case .test:
                return
            case .teamInvite:
                Task { await self.invitesVM.rejectInvite(teamId: notification.relatedId) }
            case .taskUpdated:
                return
            }
        }
    }
    
    private func connectFunc() {
        connectionsVM.acceptConnection(from: notification.fromUID, notificationId: notification.id)
        notificationsViewModel.updateNotificationStatus(notificationId: notification.id, newStatus: .accepted) { _ in }
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

extension TeamInvitesViewModel {
    @MainActor
    func rejectInvite(teamId: String) async {
        // If your real implementation exists elsewhere, this shim will be ignored.
        // Implement rejection logic here if needed.
    }
}
