//
//  NotificationRowView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/25/25.
//

import SwiftUI
import LoremSwiftum

struct NotificationRowView: View {
    let notification: NotificationFB
    
    var body: some View {
        row
    }
    
    private var row: some View {
        VStack {
            HStack {
                (Text(notification.title).bold() + Text(" " + notification.message))
                    .font(.body)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            buttons
        }
        .padding(K.UI.padding*2)
        .background {
            RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                .fill(Color(.listRow))
        }
    }
    
    private var buttons: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                
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
            Button {
                
            } label: {
                Text("Connect")
                    .padding(K.UI.padding)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                            .fill(Color.indigo)
                    }
            }
            .buttonStyle(.plain)
        }
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
}
