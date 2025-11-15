//
//  MyAssignedTasksViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/14/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class MyAssignedTasksViewModel: ObservableObject {
    @Published var tasks: [TaskFB] = []
    @Published var visibleTasks: [TaskFB] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    var me: String? { Auth.auth().currentUser?.uid }

    /// Load all tasks where the assigneeUserUIDs array contains my UID
    func loadAssignedTasks() async {
        guard let me else {
            self.tasks = []
            self.errorMessage = "Not signed in."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // assigneeUserUIDs must be stored as [String] (array of user UIDs) on each task document
            let query = TaskModel.collection
                .whereField("assigneeUserUIDs", arrayContains: me)

            let snap = try await query.getDocuments()

            var decoded: [TaskFB] = []
            for doc in snap.documents {
                let data = doc.data()
                let item = TaskFB(data: data, documentId: doc.documentID)
                decoded.append(item)
            }

            print("Fetched \(decoded.count) assigned tasks")
            for t in decoded {
                print("Task \(t.documentId) – title: \(t.title) – due: \(String(describing: t.dueAt)) – assignees: \(t.assigneeUserUIDs)")
            }

            // Same sort as TaskViewModel: unfinished first, then updatedAt desc
            self.tasks = decoded.sorted {
                let aDone = $0.status.lowercased() == "done"
                let bDone = $1.status.lowercased() == "done"
                if aDone != bDone {
                    return !aDone && bDone
                }
                let aDate = $0.updatedAt ?? .distantPast
                let bDate = $1.updatedAt ?? .distantPast
                return aDate > bDate
            }
            
            

        } catch {
            print("Error loading assigned tasks: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.tasks = []
        }

        isLoading = false
    }
    /// Returns tasks that fall within [start, end).
    /// A task is included if:
    /// - its `dueAt` is within [start, end), OR
    /// - its scheduled range [`scheduledStartAt`, `scheduledEndAt`] overlaps [start, end).
    func tasksScheduled(between start: Date, and end: Date, calendar: Calendar = .current) -> [TaskFB] {
        tasks.filter { task in
            let rangeStart = start
            let rangeEnd = end
            
            // Match direct due date
            var matchesDue = false
            if let due = task.dueAt {
                matchesDue = (due >= rangeStart && due < rangeEnd)
            }
            
            // Match scheduled span (inclusive on both ends at day-level),
            // using overlap check for time intervals.
            var matchesScheduled = false
            if let s = task.scheduledStartAt, let e = task.scheduledEndAt {
                // Overlap if start < rangeEnd && end >= rangeStart
                matchesScheduled = (s < rangeEnd && e >= rangeStart)
            }
            
            return matchesDue || matchesScheduled
        }
    }

    /// Returns tasks whose `dueAt` is on the given day
    func tasksScheduled(on day: Date, calendar: Calendar = .current) -> [TaskFB] {
        let startOfDay = calendar.startOfDay(for: day)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return tasksScheduled(between: startOfDay, and: endOfDay, calendar: calendar)
    }

    /// Updates `visibleTasks` so it only includes tasks scheduled on the given days.
    /// Pass in the days that are currently visible in your calendar view.
    func updateVisibleTasks(for days: [Date], calendar: Calendar = .current) {
        // Normalize days to their start-of-day so comparisons are stable
        let normalizedDays = days.map { calendar.startOfDay(for: $0) }
        
        var result: [TaskFB] = []
        var seen = Set<String>()
        
        // Collect tasks that are scheduled on any of the visible days
        for day in normalizedDays {
            let dayTasks = tasksScheduled(on: day, calendar: calendar)
            for task in dayTasks where !seen.contains(task.id) {
                seen.insert(task.id)
                result.append(task)
            }
        }
        
        visibleTasks = result
        
        print("Visible days: \(normalizedDays)")
        print("Visible tasks count: \(visibleTasks.count)")
        for t in visibleTasks {
            print("Visible task \(t.documentId) – due: \(String(describing: t.dueAt)) – start: \(String(describing: t.scheduledStartAt)) – end: \(String(describing: t.scheduledEndAt))")
        }
    }
}
