//
//  TaskModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/8/25.
//

import SwiftUI
import FirebaseFirestore

struct TaskModel: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String              // was notes
    var status: String                   // e.g. "open"
    var priority: Int                    // Int in your docs
    var dueAt: Timestamp?
    var createdAt: Timestamp?
    var creatorUID: String               // was createdBy
    var updatedAt: Timestamp?             // was lastUpdatedAt
    var assigneeUIDs: [String: String]?  // id -> "user" | "team"
    var teamId: String?                 // optional team scope
    var projectId: String?               // optional, present in your docs

    static var collection: CollectionReference {
        Firestore.firestore().collection("tasks")
    }
}


extension TaskModel {
    var priorityLabel: String {
        switch priority {
        case 1: return "Low"
        case 2: return "Normal"
        case 3: return "Medium"
        case 4: return "High"
        case 5: return "Critical"
        default: return "Unknown"
        }
    }
}
