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
    var description: String              // was notes
    var status: String                   // e.g. "open"
    var priority: Int                    // Int in your docs
    var dueAt: Timestamp?

    var scheduledStartAt: Timestamp?
    var scheduledEndAt: Timestamp?

    var createdAt: Timestamp?
    var creatorUID: String               // was createdBy
    var updatedAt: Timestamp?            // was lastUpdatedAt
    var assigneeUserUIDs: [String]?      // direct user assignees
    var assigneeStates: [String: String]?
    var teamId: String?
    var projectId: String?
    var checklist: [ChecklistItem]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case status
        case priority
        case dueAt
        case scheduledStartAt
        case scheduledEndAt
        case createdAt
        case creatorUID
        case updatedAt
        case assigneeUserUIDs
        case assigneeStates
        case teamId
        case projectId
        case checklist
    }

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


struct TaskFB: Identifiable {
    var id: String { documentId }
    
    var documentId: String
    var title: String
    var description: String
    var status: String
    var priority: Int
    var dueAt: Date?
    
    var scheduledStartAt: Date?
    var scheduledEndAt: Date?
    
    var createdAt: Date?
    var creatorUID: String
    var updatedAt: Date?
    
    var assigneeUserUIDs: [String]        // direct user assignees
    var assigneeStates: [String: String]
    var teamId: String?
    var projectId: String?
    var checklist: [ChecklistItem]

    init(data: [String: Any], documentId: String) {
        self.documentId = documentId
        
        self.title = data["title"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.status = data["status"] as? String ?? ""
        self.priority = data["priority"] as? Int ?? 0
        
        self.dueAt = (data["dueAt"] as? Timestamp)?.dateValue()
        self.scheduledStartAt = (data["scheduledStartAt"] as? Timestamp)?.dateValue()
        self.scheduledEndAt = (data["scheduledEndAt"] as? Timestamp)?.dateValue()
        
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        self.creatorUID = data["creatorUID"] as? String ?? ""
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        
        self.assigneeUserUIDs = data["assigneeUserUIDs"] as? [String] ?? []
        self.assigneeStates = data["assigneeStates"] as? [String: String] ?? [:]
        self.teamId = data["teamId"] as? String
        self.projectId = data["projectId"] as? String
        
        self.checklist = (data["checklist"] as? [[String: Any]])?.compactMap { dict in
            guard let text = dict["text"] as? String,
                  let isChecked = dict["isChecked"] as? Bool else { return nil }
            return ChecklistItem(text: text, isChecked: isChecked)
        } ?? []
    }
}

extension TaskFB {
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
