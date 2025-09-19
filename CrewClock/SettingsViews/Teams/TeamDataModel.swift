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
    var members: [String] = []
}

struct MemberEntry {
    let uid: String
    var role: String = "member"
    var addedAt: Date? = nil
}
