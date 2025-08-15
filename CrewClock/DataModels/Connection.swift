//
//  Connection.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/14/25.
//

import SwiftUI
import FirebaseFirestore

struct Connection: Identifiable {
    let id: String
    let uids: [String]
    let initiator: String
    let status: String
    let createdAt: Timestamp?
    let updatedAt: Timestamp?
    let lastActionBy: String?
}

