//
//  NotificationType.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/23/25.
//

import SwiftUI

enum NotificationType: String, Codable {
    case connectInvite, connectionAccepted, projectInvite, taskAssigned, commentMention, scheduleUpdate
    
    var message: String {
        switch self {
        case .connectInvite:
            return "wants to connect on CrewClock. Press Connect to accept or Reject."
        case .projectInvite:
            return "invited you to join to their project. Press Accept to accept or Reject."
        case .taskAssigned:
            return "gave you task. Press Accept the task or Reject."
        case .commentMention:
            return "mentioned you in the comment."
        case .scheduleUpdate:
            return "updated their schedule."
        case .connectionAccepted:
            return "accepted you invite to connect."
        }
    }
}
