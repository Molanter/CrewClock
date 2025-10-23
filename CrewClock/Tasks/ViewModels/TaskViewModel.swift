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
            if let err = err as NSError? {
                // If it's an index error, fall back to a simpler query that does not require a composite index
                let code = FirestoreErrorCode(_nsError: err).code
                if code == .failedPrecondition || err.localizedDescription.lowercased().contains("index") {
                    var fallback: Query = TaskModel.collection
                    if let me = self.me {
                        switch self.filter {
                        case .assignedToMe:
                            fallback = fallback.whereField("assigneeUIDs", arrayContains: me)
                        case .createdByMe:
                            fallback = fallback.whereField("creatorUID", isEqualTo: me)
                        case .all:
                            break
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
            var decoded: [TaskModel] = []
            var firstError: String?
            snap?.documents.forEach { doc in
                do {
                    let item = try doc.data(as: TaskModel.self)
                    decoded.append(item)
                } catch {
                    if firstError == nil {
                        firstError = "Decode failed for \(doc.documentID): \(error.localizedDescription)"
                    }
                }
            }
            // Sort: incomplete tasks first, then by updatedAt descending
            self.tasks = decoded.sorted {
                let aDone = $0.status.lowercased() == "done"
                let bDone = $1.status.lowercased() == "done"
                if aDone != bDone {
                    return !aDone && bDone // unfinished before done
                }
                let aDate = $0.updatedAt?.dateValue() ?? .distantPast
                let bDate = $1.updatedAt?.dateValue() ?? .distantPast
                return aDate > bDate // newer first
            }
            self.errorMessage = firstError
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
            query = baseFiltered.whereField("assigneeUIDs", arrayContains: me)
        case .createdByMe:
            query = baseFiltered.whereField("creatorUID", isEqualTo: me)
        case .all:
            // All = (assigned to me) OR (created by me)
            let orFilter = Filter.orFilter([
                Filter.whereField("creatorUID", isEqualTo: me),
                Filter.whereField("assigneeUIDs", arrayContains: me)
            ])
            query = baseFiltered.whereFilter(orFilter)
        }
        attachListener(with: query)
    }

    func stopListening() {
        listener?.remove(); listener = nil
    }

    /// Note: Queries filter on "creatorUID" / "assigneeUIDs" and sort by "dueAt" (Timestamp?) and "updatedAt" (Timestamp).
    /// Ensure creatorUID equals the current Auth.uid. Assigned filter uses ARRAY_CONTAINS on "assigneeUIDs".
    /// Create rules should allow: request.resource.data.creatorUID == request.auth.uid
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
        if let assignedTo { data["assigneeUIDs"] = [assignedTo] }
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

    func setStatus(taskId: String, status: String) async throws {
        let ref = TaskModel.collection.document(taskId)
        try await ref.setData([
            "status": status,
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }

    /// Update an existing task after editing.
    /// Pass the full edited `TaskModel`. Fields set to `nil`/empty will be removed in Firestore.
    @discardableResult
    func updateTask(_ task: TaskModel) async throws -> Void {
        // Ensure we have an ID to update
        guard let taskId = task.id else {
            throw NSError(domain: "TaskVM", code: 400, userInfo: [NSLocalizedDescriptionKey: "Task has no id."])
        }

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

        // assigneeUIDs: set non-empty or delete
        if let assignees = task.assigneeUIDs, !assignees.isEmpty {
            data["assigneeUIDs"] = assignees
        } else {
            data["assigneeUIDs"] = FieldValue.delete()
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
        let recipients = task.assigneeUIDs ?? []
        try await manager.upsert(
            data,
            at: FSPath.Task(id: taskId),
            merge: true,
            notify: !recipients.isEmpty,
            notifyType: .taskAssigned,
            notifyRecipients: recipients,
            notifyTitleOverride: "Task updated",
            notifyMessageOverride: task.title
        )
    }
}
