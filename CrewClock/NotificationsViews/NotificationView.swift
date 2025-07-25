//
//  NotificationView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/25/25.
//

import SwiftUI

struct NotificationView: View {
    var notifications: [NotificationFB] = [
        NotificationFB(
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
        ),
        NotificationFB(
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
        ),
        NotificationFB(
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
        )
    ]
    var body: some View {
        list
    }
    
    private var list: some View {
        List {
            ForEach(notifications) { notification in
                NotificationRowView(notification: notification)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .padding(.bottom, K.UI.padding*2)
            }
        }
    }
}

#Preview {
    NotificationView()
}
