//
//  SheetViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 5/28/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class SpreadSheetViewModel: ObservableObject {
    let db = Firestore.firestore()
    let user = Auth.auth().currentUser

    @Published var spreadsheetUrl: String = ""
    @Published var errorMessage: String?

    
    func saveSpreadsheetId(id: String) {
        guard let uid = user?.uid else {
            self.errorMessage = "❌ User not signed in"
            return
        }

        db.collection("users").document(uid).setData([
            "spreadsheetId": id
        ], merge: true) { error in
            if let error = error {
                print("❌ Failed to save spreadsheet ID: \(error)")
                self.errorMessage = "❌ Could not save spreadsheet ID."
            } else {
                print("✅ Spreadsheet ID saved to Firestore for user \(uid)")
                self.errorMessage = ""
                self.submitLog()
            }
        }
    }
    
    func submitLog() {
        guard let uid = user?.uid else { return }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), let spreadsheetId = data["spreadsheetId"] as? String {
                self.db.collection("logs").addDocument(data: [
                    "user": self.user?.email ?? "unknown",
                    "date": "2025-05-29",
                    "start": "09:00",
                    "end": "17:00",
                    "notes": "Framed kitchen walls",
                    "spreadsheetId": spreadsheetId
                ]) { err in
                    if let err = err {
                        print("❌ Error writing to Firestore: \(err)")
                    } else {
                        print("✅ Log with spreadsheet ID submitted to Firebase")
                    }
                }
            } else {
                print("❌ Spreadsheet ID not found for user")
            }
        }
    }
    
    func fetchSavedSpreadsheetId(completion: @escaping (String?) -> Void) {
        guard let uid = user?.uid else {
            self.errorMessage = "❌ User not signed in"
            completion(nil)
            return
        }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("❌ Failed to fetch spreadsheet ID: \(error)")
                self.errorMessage = "❌ Error fetching spreadsheet ID."
                completion(nil)
                return
            }

            if let data = snapshot?.data(), let spreadsheetId = data["spreadsheetId"] as? String {
                completion(spreadsheetId)
            } else {
                self.errorMessage = "❌ No spreadsheet ID found."
                completion(nil)
            }
        }
    }
}
