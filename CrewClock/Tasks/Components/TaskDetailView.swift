//
//  TaskDetailView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/15/25.
//


import SwiftUI
import FirebaseFirestore

struct TaskDetailView: View {
    let task: TaskModel
    @ObservedObject var vm: TaskViewModel
    @State private var saving = false

    var body: some View {
        Form {
            Section("Info") {
                Text(task.title).font(.headline)
                if !task.notes.isEmpty { Text(task.notes) }
                if let due = task.dueAt?.dateValue() {
                    LabeledContent("Due", value: due.formatted(date: .abbreviated, time: .omitted))
                }
                LabeledContent("Priority", value: task.priority.capitalized)
                LabeledContent("Status", value: task.status.capitalized)
            }

            Section("Actions") {
                Button("Mark Accepted") { setStatus("accepted") }
                Button("Mark Rejected") { setStatus("rejected") }
                Button("Mark Done") { setStatus("done") }
            }
        }
        .navigationTitle("Task")
        .toolbar { if saving { ProgressView() } }
    }

    private func setStatus(_ status: String) {
        guard let id = task.id else { return }
        saving = true
        Task {
            defer { saving = false }
            do { try await vm.setStatus(taskId: id, status: status) }
            catch { print("Status update failed:", error) }
        }
    }
}
