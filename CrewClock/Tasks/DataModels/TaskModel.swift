//
//  TaskModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/8/25.
//

import SwiftUI
import FirebaseFirestore

struct TaskModel: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var notes: String
    var status: String
    var priority: String
    var dueAt: Timestamp?
    var createdAt: Timestamp
    var createdBy: String
    var assignedTo: String?     // nil or uid
    var teamId: String          // "" if none
    var lastUpdatedAt: Timestamp

    static let collection = Firestore.firestore().collection("tasks")
}
