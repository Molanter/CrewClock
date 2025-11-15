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
    @Published var tasks: [TaskFB] = []
    @Published var filter: TaskFilter = .assignedToMe
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let manager = FirestoreManager()

    var me: String? { Auth.auth().currentUser?.uid }
    
    private func attachListener(with query: Query) {
        // Tear down any existing listener
        listener?.remove(); listener = nil
        isLoading = true
        errorMessage = nil

        listener = query.addSnapshotListener { [weak self] snap, err in
            guard let self = self else { return }
            self.isLoading = false

            // Handle Firestore errors
            if let err = err as NSError? {
                let code = FirestoreErrorCode(_nsError: err).code
                if code == .failedPrecondition || err.localizedDescription.lowercased().contains("index") {
                    // If it's an index error, fall back to a simpler query that does not require a composite index
                    var fallback: Query = TaskModel.collection
                    if let me = self.me {
                        switch self.filter {
                        case .assignedToMe:
                            // Fallback: tasks directly assigned to me, without extra ordering
                            fallback = fallback.whereField("assigneeUserUIDs", arrayContains: me)
                        case .createdByMe:
                            fallback = fallback.whereField("creatorUID", isEqualTo: me)
                        case .all:
                            let orFilter = Filter.orFilter([
                                Filter.whereField("creatorUID", isEqualTo: me),
                                Filter.whereField("assigneeUserUIDs", arrayContains: me)
                            ])
                            fallback = fallback.whereFilter(orFilter)
                        }
                    }
                    self.errorMessage = "Using fallback (no sort). Create Firestore index to enable full sorting."
                    self.attachListener(with: fallback)
                    return
                }

                self.errorMessage = err.localizedDescription
                self.tasks = []
                return
            }

            // Decode documents into TaskFB models
            var decoded: [TaskFB] = []
            snap?.documents.forEach { doc in
                let data = doc.data()
                let item = TaskFB(data: data, documentId: doc.documentID)
                decoded.append(item)
            }

            // Sort: incomplete tasks first, then by updatedAt descending
            self.tasks = decoded.sorted {
                let aDone = $0.status.lowercased() == "done"
                let bDone = $1.status.lowercased() == "done"
                if aDone != bDone {
                    return !aDone && bDone // unfinished before done
                }
                let aDate = $0.updatedAt ?? .distantPast
                let bDate = $1.updatedAt ?? .distantPast
                return aDate > bDate // newer first
            }

            // No per-document decode error reporting here because TaskFB init is non-throwing.
            self.errorMessage = nil
        }
    }

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
        // Preferred query: requires composite index (dueAt ASC, lastUpdatedAt DESC [+ filter field])
        let baseAll: Query = TaskModel.collection
            .order(by: "dueAt", descending: false)
            .order(by: "updatedAt", descending: true)
        let baseFiltered: Query = TaskModel.collection
            .order(by: "updatedAt", descending: true) // single sort avoids composite index with equality filters

        let query: Query
        switch filter {
        case .assignedToMe:
            // Tasks directly assigned to me
            query = baseFiltered.whereField("assigneeUserUIDs", arrayContains: me)

        case .createdByMe:
            query = baseFiltered.whereField("creatorUID", isEqualTo: me)

        case .all:
            // All = (created by me) OR (assigned directly to me)
            let orFilter = Filter.orFilter([
                Filter.whereField("creatorUID", isEqualTo: me),
                Filter.whereField("assigneeUserUIDs", arrayContains: me)
            ])
            query = baseFiltered.whereFilter(orFilter)
        }
        attachListener(with: query)
    }

    func stopListening() {
        listener?.remove(); listener = nil
    }

    /// Note: Queries filter on "creatorUID" / "assigneeUserUIDs" and sort by "dueAt" (Timestamp?) and "updatedAt" (Timestamp).
    /// Ensure creatorUID equals the current Auth.uid. Assigned filter uses ARRAY_CONTAINS on "assigneeUserUIDs".
    func createTask(
        title: String,
        notes: String = "",
        priority: Int = 0,
        dueAt: Timestamp? = nil,
        assignedTo: String? = nil,
        teamId: String = "",
        projectId: String? = nil
    ) async throws {
        guard let me else { throw NSError(domain: "TaskVM", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"]) }

        let now = Timestamp(date: Date())
        var data: [String: Any] = [
            "title": title,
            "description": notes,
            "status": "open",
            "priority": priority,
            "createdAt": now,
            "creatorUID": me,
            "updatedAt": now
        ]
        if let dueAt { data["dueAt"] = dueAt }
        if let assignedTo {
            // Direct user assignment: store in assigneeUserUIDs array
            data["assigneeUserUIDs"] = [assignedTo]
            // Initialize per-assignee state as "sent" for this user
            data["assigneeStates"] = [assignedTo: "sent"]
        }
        if !teamId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["teamId"] = teamId
        }
        if let projectId, !projectId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["projectId"] = projectId
        }

        // Write the document
        let ref = TaskModel.collection.document()
        try await ref.setData(data)
    }

    /// Update the task's global status and the current user's per-assignee status,
    /// then persist via `updateTask(_:)` so the full model (including assigneeStates array/map)
    /// is written consistently.
    func setStatus(for task: TaskFB, status: String) async throws {
        var updatedTask = task
        // Update global task status
        updatedTask.status = status
        
        // Update per-user assignee state in the model
        if let me = me {
            updatedTask.assigneeStates[me] = status
        }
        
        // Persist via the central update method (handles deletes, notifications, etc.)
        try await updateTask(updatedTask)
    }

    /// Update an existing task after editing.
    /// Pass the full edited `TaskModel`. Fields set to `nil`/empty will be removed in Firestore.
    @discardableResult
    func updateTask(_ task: TaskFB) async throws -> Void {

        var data: [String: Any] = [
            "title": task.title,
            "description": task.description,
            "status": task.status,
            "priority": task.priority,
            "updatedAt": Timestamp(date: Date())
        ]

        // dueAt: set or delete
        if let dueAt = task.dueAt {
            data["dueAt"] = dueAt
        } else {
            data["dueAt"] = FieldValue.delete()
        }

        // assigneeUserUIDs: set non-empty or delete
        if !task.assigneeUserUIDs.isEmpty {
            data["assigneeUserUIDs"] = task.assigneeUserUIDs
        } else {
            data["assigneeUserUIDs"] = FieldValue.delete()
        }

        // assigneeStates: set non-empty or delete
        if !task.assigneeStates.isEmpty {
            data["assigneeStates"] = task.assigneeStates
        } else {
            data["assigneeStates"] = FieldValue.delete()
        }

        // teamId: set non-empty or delete
        if let teamId = task.teamId, !teamId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["teamId"] = teamId
        } else {
            data["teamId"] = FieldValue.delete()
        }

        // projectId: set non-empty or delete
        if let projectId = task.projectId, !projectId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["projectId"] = projectId
        } else {
            data["projectId"] = FieldValue.delete()
        }
        let recipients = task.assigneeUserUIDs ?? []
        try await manager.upsert(
            data,
            at: FSPath.Task(id: task.id),
            merge: true,
            notify: !recipients.isEmpty,
            notifyType: .taskAssigned,
            notifyRecipients: recipients,
            notifyTitleOverride: "Task updated",
            notifyMessageOverride: task.title
        )
    }
}
