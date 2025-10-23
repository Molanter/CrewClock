//
//  NotificationType.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/23/25.
//

import SwiftUI

enum NotificationType: String, Codable {
    case connectInvite, teamInvite, connectionAccepted, projectInvite, taskAssigned, taskUpdated, commentMention, scheduleUpdate, test
    
    var message: String {
        switch self {
        case .connectInvite:
            return "wants to connect on CrewClock. Press Connect to accept or Reject."
        case .projectInvite:
            return "invited you to join to their project. Press Accept to accept or Reject."
        case .taskAssigned:
            return "gave you task. Press Accept the task or Reject."
        case .taskUpdated:
            return "updated task details."
        case .commentMention:
            return "mentioned you in the comment."
        case .scheduleUpdate:
            return "updated their schedule."
        case .connectionAccepted:
            return "accepted you invite to connect."
        case .test:
            return "just testing"
        case .teamInvite:
            return "invited you to join to their team. Press Accept to accept or Reject."
        }
    }
    
    var title: String {
        switch self {
        case .connectInvite:
            return "Connect Request"
        case .connectionAccepted:
            return "Connection Accepted"
        case .projectInvite:
            return "Invitation to join to Project"
        case .commentMention:
            return "You were mentioned"
        case .scheduleUpdate:
            return "Schedule Update"
        case . test:
            return "TEST push notification"
        case .teamInvite:
            return "Join my Team"
        case .taskAssigned:
            return "Task Assigned"
        case .taskUpdated:
            return "Task Updated"
        }
    }
    
    var mainAction: String {
        switch self {
        case .connectInvite, .connectionAccepted:
            return "Connect"
        case .projectInvite, .taskAssigned, .commentMention, .scheduleUpdate, .test, .teamInvite:
            return "Accept"
        case .taskUpdated:
            return "View"
        }
    }
}
