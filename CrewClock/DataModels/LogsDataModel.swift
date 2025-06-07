//
//  LogsDataModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/3/25.
//



import Foundation
import FirebaseFirestore

struct CrewLog: Identifiable {
    var id: String { documentID }
    var documentID: String
    var name: String
    var comment: String
    var date: Date
    var timeStarted: String
    var timeFinished: String
    var crewUID: [String]
    var expenses: Double

    init(data: [String: Any]) {
        self.documentID = data["id"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.comment = data["comment"] as? String ?? ""
        self.date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        self.timeStarted = data["time_started"] as? String ?? ""
        self.timeFinished = data["time_finished"] as? String ?? ""
        self.crewUID = data["crew_uid"] as? [String] ?? []
        self.expenses = data["expenses"] as? Double ?? 0.0
    }
}
