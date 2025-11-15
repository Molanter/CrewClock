//
//  LogsDataModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/3/25.
//



import Foundation
import FirebaseFirestore

struct LogModel {
    var logId: String
    var projectName: String
    var comment: String
    var date: Date
    var timeStarted: Date
    var timeFinished: Date
    var crewUID: [String] // user UIDs
    var expenses: Double
    var row: Int

    init(logId: String = "", projectName: String = "", comment: String = "", date: Date = Date(), timeStarted: Date = Date(), timeFinished: Date = Date(), crewUID: [String] = [], expenses: Double = 0.0, row: Int = 0) {
        self.logId = logId
        self.projectName = projectName
        self.comment = comment
        self.date = date
        self.timeStarted = timeStarted
        self.timeFinished = timeFinished
        self.crewUID = crewUID
        self.expenses = expenses
        self.row = row
    }
}

struct LogFB: Identifiable, Codable {
    var id: String { documentID }
    var documentID: String
    var spreadsheetId: String
    var row: Int
    var projectName: String
    var comment: String
    var date: Date
    var timeStarted: Date
    var timeFinished: Date
    var crewUID: [String] // user UIDs
    var expenses: Double

    init(data: [String: Any], documentId: String) {
        self.documentID = documentId
        self.spreadsheetId = data["spreadsheetId"] as? String ?? ""
        self.row = data["row"] as? Int ?? 0
        self.projectName = data["projectName"] as? String ?? ""
        self.comment = data["comment"] as? String ?? ""
        self.date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        self.timeStarted = (data["timeStarted"] as? Timestamp)?.dateValue() ?? Date()
        self.timeFinished = (data["timeFinished"] as? Timestamp)?.dateValue() ?? Date()
        self.crewUID = data["crewUID"] as? [String] ?? []
        self.expenses = data["expenses"] as? Double ?? 0.0
    }
}
