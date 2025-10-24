//
//  LogsViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/3/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

class LogsViewModel: ObservableObject {
    @Published var logs: [LogFB] = []

    private var db = Firestore.firestore()
    private let collectionName = "logs"

    
    // MARK: Unified Fetch Logs Function (Both Collections)
    func fetchLogs() {
        fetchLogsFromLogs()
        fetchLogsForSheets()
    }

    // MARK: Fetch Logs for Sheets
    private func fetchLogsForSheets() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let logsRef = Firestore.firestore().collection("logsForSheets")
        logsRef
            .whereField("createdBy", isEqualTo: userId)
            .getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("Error fetching logsForSheets: \(error)")
                } else if let documents = querySnapshot?.documents {
                    var processedLogs: [LogFB] = []

                    for document in documents {
                        var data = document.data()
                        let docId = document.documentID
                        data["documentID"] = docId
                        let logModel = LogFB(data: data, documentId: docId)
                        processedLogs.append(logModel)
                    }

                    // Append logs from logsForSheets to existing logs
                    self?.logs.append(contentsOf: processedLogs)
                } else {
                    print("No documents found in logsForSheets")
                }
            }
    }
    
    //MARK: Fetch Logs
    private func fetchLogsFromLogs() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let logsRef = Firestore.firestore().collection(collectionName)
        logsRef
            .whereField("createdBy", isEqualTo: userId)
            .getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("Error fetching logs: \(error)")
                } else if let documents = querySnapshot?.documents {
                    self?.logs = []
                    var processedLogs: [LogFB] = []

                    for document in documents {
                        var data = document.data()
                        let docId = document.documentID
                        data["documentID"] = docId
                        let logModel = LogFB(data: data, documentId: docId)
                        processedLogs.append(logModel)
                    }

                    self?.logs = processedLogs
                } else {
                    print("No documents found")
                    self?.logs = []
                }
            }
    }

    // MARK: Add Log to 'logs'
    func addLogToLogs(_ log: LogModel) {
        guard let user = Auth.auth().currentUser else { return }

        let logData: [String: Any] = [
            "user": user.email ?? "unknown",
            "date": Timestamp(date: log.date),
            "timeStarted": log.timeStarted,
            "timeFinished": log.timeFinished,
            "comment": log.comment,
            "projectName": log.projectName,
            "crewUID": log.crewUID,
            "expenses": log.expenses,
            "createdBy": user.uid
        ]

        db.collection("logs").addDocument(data: logData) { [weak self] err in
            if let err = err {
                print("❌ Error writing to Firestore: \(err)")
            } else {
                print("✅ Log submitted to Firebase logs collection")
                self?.fetchLogsFromLogs()
            }
        }
    }

    // MARK: Add Log to 'logsForSheets'
    func addLogToLogsForSheets(_ log: LogModel) {
        guard let user = Auth.auth().currentUser else { return }

        db.collection("users").document(user.uid).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data(), let spreadsheetId = data["spreadsheetId"] as? String {
                let logData: [String: Any] = [
                    "user": user.email ?? "unknown",
                    "date": Timestamp(date: log.date),
                    "timeStarted": log.timeStarted,
                    "timeFinished": log.timeFinished,
                    "comment": log.comment,
                    "projectName": log.projectName,
                    "crewUID": log.crewUID,
                    "expenses": log.expenses,
                    "createdBy": user.uid,
                    "spreadsheetId": spreadsheetId
                ]

                self?.db.collection("logsForSheets").addDocument(data: logData) { err in
                    if let err = err {
                        print("❌ Error writing to Firestore logsForSheets: \(err)")
                    } else {
                        print("✅ Log submitted to Firebase logsForSheets collection")
                    }
                }
            } else {
                print("❌ Spreadsheet ID not found for user")
            }
        }
    }

    // MARK: Unified Add Log Function
    func addLog(_ log: LogModel, toSpreadsheet: Bool = false) {
        if toSpreadsheet {
            addLogToLogsForSheets(log)
        } else {
            addLogToLogs(log)
        }
    }
    
    // MARK: Update/Edit Log (Routes depending on location)
    func updateLog(log: LogModel) {
        let logsRef = db.collection("logs").document(log.logId)
        let logsForSheetsRef = db.collection("logsForSheets").document(log.logId)

        logsRef.getDocument { [weak self] (snapshot, error) in
            if let doc = snapshot, doc.exists {
                print("Found log in 'logs'")
                self?.updateLogInLogs(log)
            } else {
                logsForSheetsRef.getDocument { [weak self] (snapshot, error) in
                    if let doc = snapshot, doc.exists {
                        print("Found log in 'logsForSheets'")
                        self?.updateLogInLogsForSheets(log)
                    } else {
                        print("❌ Log not found in either collection")
                    }
                }
            }
        }
    }

    // MARK: Private Helpers for Updating
    private func updateLogInLogs(_ log: LogModel) {
        let ref = db.collection("logs").document(log.logId)
        let updatedData = buildUpdatedLogData(log)

        ref.updateData(updatedData) { error in
            if let error = error {
                print("❌ Error updating log in 'logs': \(error)")
            } else {
                print("✅ Log updated successfully in 'logs'")
                self.fetchLogsFromLogs()
            }
        }
    }

    private func updateLogInLogsForSheets(_ log: LogModel) {
        let ref = db.collection("logsForSheets").document(log.logId)
        let updatedData = buildUpdatedLogData(log)

        ref.updateData(updatedData) { error in
            if let error = error {
                print("❌ Error updating log in 'logsForSheets': \(error)")
            } else {
                print("✅ Log updated successfully in 'logsForSheets'")
                self.fetchLogsFromLogs()
            }
        }
    }

    private func buildUpdatedLogData(_ log: LogModel) -> [String: Any] {
        var updatedData: [String: Any] = [:]

        if !log.projectName.isEmpty {
            updatedData["projectName"] = log.projectName
        }

        if !log.comment.isEmpty {
            updatedData["comment"] = log.comment
        }

        updatedData["date"] = log.date
        updatedData["timeStarted"] = log.timeStarted
        updatedData["timeFinished"] = log.timeFinished

        if !log.crewUID.isEmpty {
            updatedData["crewUID"] = log.crewUID
        }

        updatedData["expenses"] = log.expenses

        return updatedData
    }

    //MARK: Delete Log (Search both collections)
    func deleteLog(_ log: LogFB) {
        let logsRef = db.collection("logs").document(log.documentID)
        let logsForSheetsRef = db.collection("logsForSheets").document(log.documentID)

        logsRef.getDocument { [weak self] (snapshot, error) in
            if let doc = snapshot, doc.exists {
                print("Found log in 'logs'")
                self?.deleteLogInLogs(log.documentID)
            } else {
                logsForSheetsRef.getDocument { [weak self] (snapshot, error) in
                    if let doc = snapshot, doc.exists {
                        print("Found log in 'logsForSheets'")
                        self?.deleteLogInLogsForSheets(log.documentID)
                    } else {
                        print("❌ Log not found in either collection for deletion")
                    }
                }
            }
        }
    }

    // MARK: Private Helpers for Deleting
    private func deleteLogInLogs(_ logId: String) {
        db.collection("logs").document(logId).delete { [weak self] error in
            if let error = error {
                print("❌ Firestore delete error in 'logs':", error.localizedDescription)
            } else {
                print("✅ Deleted from 'logs'")
                self?.fetchLogsFromLogs()
            }
        }
    }

    private func deleteLogInLogsForSheets(_ logId: String) {
        db.collection("logsForSheets").document(logId).delete { [weak self] error in
            if let error = error {
                print("❌ Firestore delete error in 'logsForSheets':", error.localizedDescription)
            } else {
                print("✅ Deleted from 'logsForSheets'")
                self?.fetchLogsFromLogs()
            }
        }
    }
    
}
