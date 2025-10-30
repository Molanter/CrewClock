//
//  LogDetailViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/28/25.
//


import SwiftUI
import FirebaseFirestore

final class LogDetailViewModel: ObservableObject {
    @Published var log: LogFB?
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()
    private let collectionPath: String

    init(collectionPath: String = "logs") {
        self.collectionPath = collectionPath
    }

    func fetch(logId: String) {
        isLoading = true
        error = nil
        db.collection(collectionPath).document(logId).getDocument { [weak self] snap, err in
            guard let self else { return }
            if let err = err {
                self.error = err.localizedDescription
                self.isLoading = false
                return
            }
            guard let snap = snap, snap.exists, let data = snap.data() else {
                self.error = "Log not found."
                self.isLoading = false
                return
            }
            self.log = LogFB(data: data, documentId: snap.documentID)
            self.isLoading = false
        }
    }
}
