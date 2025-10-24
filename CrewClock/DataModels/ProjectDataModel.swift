//
//  ProjectDataModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/3/25.
//

import Foundation
import FirebaseFirestore

struct Project: Identifiable {
    @DocumentID var id: String?
    var projectName: String
    var owner: String
    var crew: [String: String] // id -> "user" | "team"
    var checklist: [ChecklistItem]
    var comments: String
    var color: String
    var startDate: Date
    var finishDate: Date
    var active: Bool
}

struct ProjectModel {
    var projectName: String
    var owner: String
    var crew: [String: String] // id -> "user" | "team"
    var checklist: [ChecklistItem]
    var comments: String
    var color: String
    var startDate: Date
    var finishDate: Date
    var active: Bool

    init(projectName: String, owner: String, crew: [String: String], checklist: [ChecklistItem], comments: String, color: String, startDate: Date, finishDate: Date, active: Bool) {
        self.projectName = projectName
        self.owner = owner
        self.crew = crew
        self.checklist = checklist
        self.comments = comments
        self.color = color
        self.startDate = startDate
        self.finishDate = finishDate
        self.active = active
    }
}

struct ProjectFB: Identifiable {
    var id: String { documentId }
    
    var documentId: String
    var name: String
    var owner: String
    var crew: [String: String] // id -> "user" | "team"
    var checklist: [ChecklistItem]
    var comments: String
    var color: String
    var startDate: Date
    var finishDate: Date
    var active: Bool
    
    init(data: [String: Any], documentId: String) {
        self.documentId = documentId
        self.name = data["projectName"] as? String ?? ""
        self.owner = data["owner"] as? String ?? ""
        self.crew = data["crew"] as? [String: String] ?? [:]
        self.checklist = (data["checklist"] as? [[String: Any]])?.compactMap { dict in
            guard let text = dict["text"] as? String, let isChecked = dict["isChecked"] as? Bool else { return nil }
            return ChecklistItem(text: text, isChecked: isChecked)
        } ?? []
        self.comments = data["comments"] as? String ?? ""
        self.color = data["color"] as? String ?? ""
        self.startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        self.finishDate = (data["finishDate"] as? Timestamp)?.dateValue() ?? Date()
        self.active = data["active"] as? Bool ?? true

    }
}
