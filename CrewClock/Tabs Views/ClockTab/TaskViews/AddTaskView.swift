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
    @State private var hasTimeRange: Bool = false
    @State private var startTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime: Date = Calendar.current.date(bySettingHour: 16, minute: 00, second: 0, of: Date()) ?? Date()
    @State private var priority: String = "Medium"
    @State private var projectName: String = ""
    @State private var usersArray: [String] = []
    @State private var didPrefill = false
    @State private var selectedEntities: [String: String] = [:] // id -> "user" | "team"
    // Checklist
    @State private var newChecklistItem: String = ""
    @State private var checklist: [ChecklistItem] = []
    
    let priorities = ["Low", "Medium", "High"]
    
    var body: some View {
        NavigationStack {
            GlassList {
                detailsSection
                
                CrewSearchAddField(
                    exclude: .constant(selectedEntities),
                    selectedEntities: $selectedEntities,
                    showAddedCrewList: true
                )
                
                checklistSection
                
                scheduleRow
                
                dueDateRow
                
                priorityRow
            }
            .navigationTitle(existingTask == nil ? "New Task" : "Edit Task")
            .toolbar { toolbar }
            .onAppear {
                checkExist()
            }
            .onChange(of: selectedEntities) { newValue in
                usersArray = newValue.compactMap { $0.value == "user" ? $0.key : nil }
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
    
    private var checklistSection: some View {
        Section(header: Text("Checklist")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Add checklist item", text: $newChecklistItem)
                        .onSubmit { addChecklistRow() }
                    Button {
                        addChecklistRow()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
                checklistList
            }
        }
    }

    private var checklistList: some View {
        ForEach(checklist) { item in
            HStack {
                Button {
                    toggleChecklistItem(id: item.id)
                } label: {
                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isChecked ? .green : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Text(item.text).foregroundColor(.primary)
                    .strikethrough(item.isChecked, color: .primary.opacity(0.5))
                    .foregroundStyle(item.isChecked ? .secondary : .primary)

                Spacer()

                Image(systemName: "minus.circle.fill")
                    .symbolRenderingMode(.multicolor)
                    .foregroundColor(.red)
                    .onTapGesture { removeChecklistItem(id: item.id) }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var scheduleRow: some View {
        Section(header: Text("Schedule")) {
            Toggle("Assign time range", isOn: $hasTimeRange.animation())
            if hasTimeRange {
                VStack(alignment: .leading, spacing: 8) {
                    DatePicker("Start", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End", selection: $endTime, in: startTime..., displayedComponents: [.date, .hourAndMinute])
                    if selectedEntities.isEmpty {
                        Text("Select at least one assignee above to schedule.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
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
            .disabled(title.isEmpty || (hasTimeRange && endTime <= startTime))
        }
    }
    
    
    //MARK: - Functions
    private func addChecklistRow() {
        let trimmed = newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        checklist.append(ChecklistItem(text: trimmed))
        newChecklistItem = ""
    }
    
    private func removeChecklistItem(id: UUID) {
        checklist.removeAll { $0.id == id }
    }
    
    private func toggleChecklistItem(id: UUID) {
        if let idx = checklist.firstIndex(where: { $0.id == id }) {
            checklist[idx].isChecked.toggle()
        }
    }
    
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
        if !selectedEntities.isEmpty { data["assigneeUIDs"] = selectedEntities }
        if hasDueDate { data["dueAt"] = Timestamp(date: dueDate) }
        if !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["projectId"] = projectName
        }
        if !checklist.isEmpty {
            data["checklist"] = checklist.map { ["id": $0.id.uuidString, "text": $0.text, "isChecked": $0.isChecked] }
        }
        if hasTimeRange {
            data["scheduledStartAt"] = Timestamp(date: startTime)
            data["scheduledEndAt"] = Timestamp(date: endTime)
        }
        Task {
            do {
                let recipients = selectedEntities.filter { $0.value == "user" }.map { $0.key }
                let taskId = try await manager.add(data, to: FSPath.Tasks(), notify: !recipients.isEmpty, notifyType: .taskAssigned, notifyRecipients: recipients)
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
        selectedEntities = t.assigneeUIDs ?? [:]
        usersArray = selectedEntities.filter { $0.value == "user" }.map { $0.key }
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
        // Optional prefill: read checklist array from Firestore if present
        if let id = t.id {
            Task {
                do {
                    let snap = try await TaskModel.collection.document(id).getDocument()
                    if let arr = snap.data()?["checklist"] as? [[String: Any]] {
                        let items = arr.compactMap { dict -> ChecklistItem? in
                            guard let idStr = dict["id"] as? String,
                                  let text = dict["text"] as? String,
                                  let uuid = UUID(uuidString: idStr) else { return nil }
                            let checked = dict["isChecked"] as? Bool ?? false
                            return ChecklistItem(id: uuid, text: text, isChecked: checked)
                        }
                        await MainActor.run {
                            self.checklist = items
                        }
                    }
                } catch {
                    print("Checklist prefill error: \(error)")
                }
            }
        }
        if let start = t.scheduledStartAt?.dateValue(), let end = t.scheduledEndAt?.dateValue() {
            hasTimeRange = true
            startTime = start
            endTime = end
        } else {
            hasTimeRange = false
        }
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
                edited.assigneeUIDs = selectedEntities.isEmpty ? nil : selectedEntities
                edited.projectId = trimmedProject.isEmpty ? nil : trimmedProject
                edited.dueAt = hasDueDate ? Timestamp(date: dueDate) : nil
                edited.scheduledStartAt = hasTimeRange ? Timestamp(date: startTime) : nil
                edited.scheduledEndAt = hasTimeRange ? Timestamp(date: endTime) : nil
                
                try await tasksVM.updateTask(edited)
                if let id = edited.id {
                    let arr = checklist.map { ["id": $0.id.uuidString, "text": $0.text, "isChecked": $0.isChecked] }
                    try await TaskModel.collection.document(id).setData(["checklist": arr], merge: true)
                }
                print("Task \(edited.id ?? "<no id>") updated via ViewModel")
            } catch {
                print("Error updating task: \(error)")
            }
        }
    }
}

#Preview {
    AddTaskView()
        .environmentObject(UserViewModel())
}
