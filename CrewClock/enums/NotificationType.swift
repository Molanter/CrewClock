//
//  NotificationType.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/23/25.
//

import SwiftUI

enum NotificationType: String, Codable {
    case connectInvite
    case projectInvite
    case taskAssigned
    case commentMention
    case scheduleUpdate
}
