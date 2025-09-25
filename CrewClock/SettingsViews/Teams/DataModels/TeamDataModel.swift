//
//  Team.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 9/12/25.
//


import Foundation
import SwiftUI


struct Team: Identifiable, Codable {
    let id: String
    var name: String
    var ownerUid: String
    var createdAt: Date
    // NEW
    var members: [TeamMemberEntry] = []
}

enum TeamRole: String, Codable, CaseIterable, Sendable {
    case owner
    case admin
    case member
    var displayName: String { String(describing: self).capitalized }
}

enum TeamMemberStatus: String, Codable, CaseIterable, Sendable {
    case invited
    case active
    case removed
    
    var displayName: String {
        switch self {
        case .invited: return "Invited"
        case .active:  return "Active"
        case .removed: return "Removed"
        }
    }
}

struct TeamMemberEntry: Codable, Identifiable, Sendable {
    var id: String { uid }
    let uid: String
    var role: TeamRole = .member
    var status: TeamMemberStatus = .invited
    var addedAt: Date? = Date.now
}

struct TeamFB: Identifiable {
    let id: String
    let name: String
    let ownerUid: String
    var members: [TeamMemberEntry]
    let image: String
    let color: Color

    var memberCount: Int { members.count }
}
