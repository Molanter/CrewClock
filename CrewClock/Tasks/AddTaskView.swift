//
//  AddTaskView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/8/25.
//

import SwiftUI
import FirebaseFirestore

struct AddTaskView: View {
    // If provided, the view runs in edit mode and pre-fills from this task
    var existingTask: TaskModel? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userVM: UserViewModel
    @EnvironmentObject private var tasksVM: TaskViewModel
    private let manager = FirestoreManager()
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var priority: String = "Medium"
    @State private var projectName: String = ""
    @State private var usersArray: [String] = []
    @State private var didPrefill = false
    
    let priorities = ["Low", "Medium", "High"]
    
    var body: some View {
        NavigationStack {
            GlassList {
                detailsSection
                
                UserSearchAddField(
                    exclude: .constant(usersArray),
                    usersArray: $usersArray,
                    showAddedCrewList: true
                )
                
                dueDateRow
                
                priorityRow
            }
            .navigationTitle(existingTask == nil ? "New Task" : "Edit Task")
            .toolbar { toolbar }
            .onAppear {
                checkExist()
            }
        }
    }
    
    private var detailsSection: some View {
        Section(header: Text("Details")) {
            TextField("Title", text: $title)
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
            projectRow
        }
    }
        
    private var projectRow: some View {
        HStack {
            Text("Select project:")
            Spacer()
            ProjectSelectorView(error: .constant(nil), text: $projectName)
        }
    }
    
    private var priorityRow: some View {
        Section(header: Text("Priority")) {
            Picker("Priority", selection: $priority) {
                ForEach(priorities, id: \.self) { level in
                    Text(level)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var dueDateRow: some View {
        Section(header: Text("Due Date")) {
            Toggle("Set due date", isOn: $hasDueDate.animation())
            if hasDueDate {
                DatePicker("Due", selection: $dueDate, displayedComponents: .date)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(existingTask == nil ? "Save" : "Update") {
                if existingTask == nil {
                    saveTask()
                } else {
                    updateTask()
                }
                dismiss()
            }
            .disabled(title.isEmpty)
        }
    }
    
    
    //MARK: - Functions
    private func saveTask() {
        let priorityValue: Int
        switch priority {
        case "Low": priorityValue = 1
        case "High": priorityValue = 5
        default: priorityValue = 3
        }
        
        var data: [String: Any] = [
            "title": title,
            "description": notes,
            "status": "open",
            "priority": priorityValue,
            "creatorUID": userVM.user?.uid ?? "unknown",
            "updatedAt": Timestamp(date: Date()),
            "createdAt": Timestamp(date: Date())
        ]
        if !usersArray.isEmpty { data["assigneeUIDs"] = usersArray }
        if hasDueDate { data["dueAt"] = Timestamp(date: dueDate) }
        if !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["projectId"] = projectName
        }
        Task {
            do {
                let taskId = try await manager.add(data, to: FSPath.Tasks(), notify: true, notifyType: .taskAssigned, notifyRecipients: usersArray)
                print("Task saved with ID: \(taskId)")
            } catch {
                print("Error saving task: \(error)")
            }
        }
    }

    /// if Task was passed in this view - then we are edding task
    private func checkExist() {
        guard !didPrefill, let t = existingTask else { return }
        didPrefill = true
        title = t.title
        notes = t.description
        usersArray = t.assigneeUIDs ?? []
        if let due = t.dueAt?.dateValue() {
            hasDueDate = true
            dueDate = due
        } else {
            hasDueDate = false
        }
        // Map priority Int -> segmented label
        switch t.priority {
        case 1: priority = "Low"
        case 5: priority = "High"
        default: priority = "Medium"
        }
        projectName = t.projectId ?? ""
    }
    
    private func updateTask() {
        let priorityValue: Int
        switch priority {
        case "Low": priorityValue = 1
        case "High": priorityValue = 5
        default: priorityValue = 3
        }
        let trimmedProject = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                guard var edited = existingTask else { return }
                // Map UI state back onto the model
                edited.title = title
                edited.description = notes
                edited.priority = priorityValue
                edited.status = existingTask?.status ?? "open"
                edited.updatedAt = Timestamp(date: Date())
                edited.assigneeUIDs = usersArray.isEmpty ? nil : usersArray
                edited.projectId = trimmedProject.isEmpty ? nil : trimmedProject
                edited.dueAt = hasDueDate ? Timestamp(date: dueDate) : nil
                
                try await tasksVM.updateTask(edited)
                print("Task \\(edited.id ?? \"<no id>\") updated via ViewModel")
            } catch {
                print("Error updating task: \\(error)")
            }
        }
    }
}

#Preview {
    AddTaskView()
        .environmentObject(UserViewModel())
}
