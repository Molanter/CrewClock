//
//  AddTaskView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/8/25.
//

import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userVM: UserViewModel
    private let manager = FirestoreManager()
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var priority: String = "Medium"
    @State private var projectName: String = ""
    @State private var usersArray: [String] = []
    
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
            .navigationTitle("New Task")
            .toolbar { toolbar }
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
            Button("Save") {
                saveTask()
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
            "assigneeUIDs": usersArray.isEmpty ? NSNull() : usersArray,
            "status": "open",
            "priority": priorityValue,
            "projectId": projectName,
            "creatorUID": userVM.user?.uid ?? "idk who"
        ]
        
        if hasDueDate {
            data["dueAt"] = dueDate
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
}

#Preview {
    AddTaskView()
        .environmentObject(UserViewModel())
}
