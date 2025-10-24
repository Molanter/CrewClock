//
//  NotificationStatus.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/23/25.
//

import SwiftUI

enum NotificationStatus: String, Codable {
    case received
    case accepted
    case rejected
    case cancelled
    case completed
}
