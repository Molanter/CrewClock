//
//  UserViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/7/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class UserViewModel: ObservableObject {
    @Published var user: UserFB?
    @Published var users: [String: UserFB] = [:]
    @Published var currentProjectName: String = ""


    private var db = Firestore.firestore()

    func fetchUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.user = UserFB(data: data, documentId: uid)
            } else {
                print("Error fetching user: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func updateUser(data: [String: Any]) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData(data) { error in
            if let error = error {
                print("Error updating user: \(error.localizedDescription)")
            } else {
                print("✅ User updated successfully")
                self.fetchUser()
            }
        }
    }

    func clockIn(log: LogModel) {
        self.user?.currentLog = log
        self.user?.working = true
        self.currentProjectName = log.projectName
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let logData: [String: Any] = [
            "logId": log.logId,
            "projectName": log.projectName,
            "comment": log.comment,
            "date": Timestamp(date: log.date),
            "timeStarted": Timestamp(date: log.timeStarted),
            "timeFinished": Timestamp(date: log.timeFinished),
            "crewUID": log.crewUID,
            "expenses": log.expenses,
            "row": log.row
        ]
        let data: [String: Any] = [
            "working": true,
            "currentLog": logData
        ]
        db.collection("users").document(uid).updateData(data) { error in
            if let error = error {
                print("Error during clock in: \(error.localizedDescription)")
            } else {
                print("✅ Clocked in successfully")
                self.fetchUser()
            }
        }
    }

    func clockOut() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let data: [String: Any] = [
            "working": false,
            "currentLog": NSNull()
        ]
        db.collection("users").document(uid).updateData(data) { error in
            if let error = error {
                print("Error during clock out: \(error.localizedDescription)")
            } else {
                print("✅ Clocked out successfully")
                self.fetchUser()
            }
        }
    }

    func addSpreadsheetId(_ spreadsheetId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData(["currentSpreadsheetId": spreadsheetId]) { error in
            if let error = error {
                print("Error updating spreadsheet ID: \(error.localizedDescription)")
            } else {
                print("✅ Spreadsheet ID updated successfully")
                self.fetchUser()
            }
        }
    }

    func addConnection(_ connection: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData([
            "connections": FieldValue.arrayUnion([connection])
        ]) { error in
            if let error = error {
                print("Error adding connection: \(error.localizedDescription)")
            } else {
                print("✅ Connection added successfully")
                self.fetchUser()
            }
        }
    }

    func removeConnection(_ connection: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData([
            "connections": FieldValue.arrayRemove([connection])
        ]) { error in
            if let error = error {
                print("Error removing connection: \(error.localizedDescription)")
            } else {
                print("✅ Connection removed successfully")
                self.fetchUser()
            }
        }
    }

    func deleteUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).delete { error in
            if let error = error {
                print("Error deleting user: \(error.localizedDescription)")
            } else {
                print("✅ User deleted successfully")
                self.fetchUser()
            }
        }
    }
    
    func fetchUser(by uid: String) {
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                let user = UserFB(data: data, documentId: document.documentID)
                DispatchQueue.main.async {
                    self.users[uid] = user
                }
            } else {
                print("User not found: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func getUser(_ uid: String) -> UserFB? {
        if let user = users[uid] {
            return user
        } else {
            fetchUser(by: uid)
            return nil
        }
    }
}
