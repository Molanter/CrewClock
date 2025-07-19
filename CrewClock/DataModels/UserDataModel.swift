//
//  UserDataModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/7/25.
//

import SwiftUI
import FirebaseFirestore

struct UserModel: Identifiable {
    var id: String { uid }
    var uid: String
    var working: Bool
    var currentSpreadsheetId: String
    var connections: [String]
    var currentLog: LogModel?

    init(uid: String = "", currentSpreadsheetId: String = "", connections: [String] = [], currentLog: LogModel? = nil, working: Bool) {
        self.uid = uid
        self.currentSpreadsheetId = currentSpreadsheetId
        self.connections = connections
        self.currentLog = currentLog
        self.working = working
    }
}

struct UserFB: Identifiable {
    var id: String { uid }
    var uid: String
    var profileImage: String
    var name: String
    var email: String
    var working: Bool
    var currentSpreadsheetId: String
    var connections: [String]
    var currentLog: LogModel?

    init(data: [String: Any], documentId: String) {
        self.uid = documentId
        self.profileImage = data["profileImage"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.working = data["working"] as? Bool ?? false
        self.currentSpreadsheetId = data["currentSpreadsheetId"] as? String ?? ""
        self.connections = data["connections"] as? [String] ?? []
        
        if let logData = data["currentLog"] as? [String: Any] {
            self.currentLog = LogModel(
                logId: logData["logId"] as? String ?? "",
                projectName: logData["projectName"] as? String ?? "",
                comment: logData["comment"] as? String ?? "",
                date: (logData["date"] as? Timestamp)?.dateValue() ?? Date(),
                timeStarted: (logData["timeStarted"] as? Timestamp)?.dateValue() ?? Date(),
                timeFinished: (logData["timeFinished"] as? Timestamp)?.dateValue() ?? Date(),
                crewUID: logData["crewUID"] as? [String] ?? [],
                expenses: logData["expenses"] as? Double ?? 0.0,
                row: logData["row"] as? Int ?? 0
            )
        } else {
            self.currentLog = nil
        }
    }
}
