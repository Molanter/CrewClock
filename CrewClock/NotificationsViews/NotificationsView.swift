//
//  NotificationsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/25/25.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    
    var notifications: [NotificationFB] {
        notificationsViewModel.notifications
    }
    
    @State private var notificationSegment = 0
    
    private var filteredNotifications: [NotificationFB] {
        if notificationSegment == 0 {
            return notifications.filter {$0.status == .received}
        } else if notificationSegment == 1 {
            return notifications.filter {$0.status == .rejected || $0.status == .cancelled}
        } else if notificationSegment == 2 {
            return notifications.filter {$0.status == .completed || $0.status == .accepted || $0.status == .rejected || $0.status == .cancelled}
        } else {
            return notifications
        }
    }
    
    var body: some View {
        segment
        list
            .onAppear {
                onAppear()
            }
    }
    
    private var list: some View {
        List {
            ForEach(filteredNotifications) { notification in
                NotificationRowView(notification: notification)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .padding(.bottom, K.UI.padding*2)
            }
        }
    }
    
    private var segment: some View {
        Picker("", selection: $notificationSegment) {
            Text("New").tag(0)
            Text("Rejected").tag(1)
            Text("Previous").tag(2)
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private func onAppear() {
        notificationsViewModel.fetchNotifications(completion: { array in notificationsViewModel.notifications = array })
    }
}

#Preview {
    NotificationsView()
}


//notifications: [
//    NotificationFB(
//        data: [
//            "title": "Test User",
//            "message": "",
//            "timestamp": Date(),
//            "recipientUID": ["test-uid"],
//            "fromUID": "from-uid",
//            "isRead": false,
//            "status": "received",
//            "type": "connectInvite",
//            "relatedId": "1234"
//        ],
//        documentId: "notif-test-1234"
//    ),
//    NotificationFB(
//        data: [
//            "title": "Test User",
//            "message": "",
//            "timestamp": Date(),
//            "recipientUID": ["test-uid"],
//            "fromUID": "from-uid",
//            "isRead": false,
//            "status": "accepted",
//            "type": "connectInvite",
//            "relatedId": "1234"
//        ],
//        documentId: "notif-test-1234"
//    ),
//    NotificationFB(
//        data: [
//            "title": "Test User",
//            "message": "",
//            "timestamp": Date(),
//            "recipientUID": ["test-uid"],
//            "fromUID": "from-uid",
//            "isRead": false,
//            "status": "completed",
//            "type": "connectInvite",
//            "relatedId": "1234"
//        ],
//        documentId: "notif-test-1234"
//    )
//]
