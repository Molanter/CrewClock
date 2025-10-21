//
//  TaskViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/15/25.
//


import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var filter: TaskFilter = .assignedToMe
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    var me: String? { Auth.auth().currentUser?.uid }

    deinit {
        listener?.remove()
    }

    func startListening() {
        listener?.remove()
        guard let me else {
            self.tasks = []
            self.errorMessage = "Not signed in."
            return
        }

        isLoading = true
        errorMessage = nil

        let base = TaskModel.collection
            .order(by: "dueAt", descending: false)
            .order(by: "lastUpdatedAt", descending: true)

        let query: Query
        switch filter {
        case .assignedToMe:
            query = base.whereField("assignedTo", isEqualTo: me)
        case .createdByMe:
            query = base.whereField("createdBy", isEqualTo: me)
        case .all:
            // if you want team-scoped “all”, add: .whereField("teamId", in: myTeamIds)
            query = base
        }

        listener = query.addSnapshotListener { [weak self] snap, err in
            guard let self = self else { return }
            self.isLoading = false
            if let err = err {
                self.errorMessage = err.localizedDescription
                self.tasks = []
                return
            }
            do {
                self.tasks = try snap?.documents.compactMap { doc in
                    try doc.data(as: TaskModel.self)
                } ?? []
            } catch {
                self.errorMessage = "Decoding error: \(error.localizedDescription)"
                self.tasks = []
            }
        }
    }

    func stopListening() {
        listener?.remove(); listener = nil
    }

    /// Create a new task; make sure rules allow create: createdBy == me
    func createTask(
        title: String,
        notes: String = "",
        priority: String = "normal",
        dueAt: Timestamp? = nil,
        assignedTo: String? = nil,
        teamId: String = ""
    ) async throws {
        guard let me else { throw NSError(domain: "TaskVM", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"]) }

        let now = Timestamp(date: Date())
        let data: [String: Any] = [
            "title": title,
            "notes": notes,
            "status": "pending",
            "priority": priority,
            "dueAt": dueAt as Any,
            "createdAt": now,
            "createdBy": me,
            "assignedTo": assignedTo as Any,
            "teamId": teamId,
            "lastUpdatedAt": now
        ]

        let ref = TaskModel.collection.document()
        try await ref.setData(data)
    }

    func setStatus(taskId: String, status: String) async throws {
        let ref = TaskModel.collection.document(taskId)
        try await ref.setData([
            "status": status,
            "lastUpdatedAt": Date.now
        ], merge: true)
    }
}
