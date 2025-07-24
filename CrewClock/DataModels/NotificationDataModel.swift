//
//  NotificationDataModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/22/25.
//



import SwiftUI
import FirebaseFirestore

struct NotificationModel: Identifiable {
    var id: String { notificationId }
    var notificationId: String
    var title: String
    var message: String
    var timestamp: Date
    var recipientUID: [String]
    var fromUID: String
    var isRead: Bool
    var status: NotificationStatus
    var type: NotificationType
    var relatedId: String

    init(notificationId: String = UUID().uuidString, title: String, message: String, timestamp: Date = Date(), recipientUID: [String], fromUID: String = "", isRead: Bool = false, status: NotificationStatus = .received, type: NotificationType, relatedId: String) {
        self.notificationId = notificationId
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.recipientUID = recipientUID
        self.fromUID = fromUID
        self.isRead = isRead
        self.status = status
        self.type = type
        self.relatedId = relatedId
    }
}

struct NotificationFB: Identifiable {
    var id: String { notificationId }
    var notificationId: String
    var title: String
    var message: String
    var timestamp: Date
    var recipientUID: [String]
    var fromUID: String
    var isRead: Bool
    var status: NotificationStatus
    var type: NotificationType
    var relatedId: String

    init(data: [String: Any], documentId: String) {
        self.notificationId = documentId
        self.title = data["title"] as? String ?? ""
        self.message = data["message"] as? String ?? ""
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        if let array = data["recipientUID"] as? [String] {
            self.recipientUID = array
        } else if let single = data["recipientUID"] as? String {
            self.recipientUID = [single]
        } else {
            self.recipientUID = []
        }
        self.fromUID = data["fromUID"] as? String ?? ""
        self.isRead = data["isRead"] as? Bool ?? false
        self.status = NotificationStatus(rawValue: data["status"] as? String ?? "") ?? .received
        self.type = NotificationType(rawValue: data["type"] as? String ?? "") ?? .connectInvite
        self.relatedId = data["relatedId"] as? String ?? ""
    }
}

