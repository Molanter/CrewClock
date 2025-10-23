//
//  AddProjectView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/4/25.
//

import SwiftUI
import Foundation
import FirebaseAuth

struct AddProjectView: View {
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var searchUserViewModel: SearchUserViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @Environment(\.dismiss) private var dismiss

    var editingProject: ProjectFB?

    private let colorsStringArray: [String] = ["blue", "yellow", "orange", "cyan", "red", "green", "mint", "purple", "pink", "indigo", "brown"]

    @State private var project: Project
    @State private var showError = false
    @State private var newChecklistItem: String = ""
    @State private var errorMessage: String = ""
    @State private var crewSearch: String = ""
    @State private var originalCrew: [String: String] = [:]
    @State private var selectedEntities: [String: String] = [:] // id -> "user" | "team"

    // Keep focus stable while list updates
    private enum FocusField: Hashable { case crewSearch }
    @FocusState private var focus: FocusField?

    // MARK: init
    init(editingProject: ProjectFB? = nil) {
        self.editingProject = editingProject
        let user = Auth.auth().currentUser
        if let editing = editingProject {
            _project = State(initialValue: Project(
                projectName: editing.name,
                owner: editing.owner,
                crew: editing.crew,
                checklist: editing.checklist,
                comments: editing.comments,
                color: editing.color,
                startDate: editing.startDate,
                finishDate: editing.finishDate,
                active: editing.active
            ))
        } else {
            _project = State(initialValue: Project(
                projectName: "",
                owner: user?.uid ?? "",
                crew: [:],
                checklist: [],
                comments: "",
                color: "",
                startDate: Date.now,
                finishDate: Date.now,
                active: true
            ))
        }
    }

    var body: some View {
        NavigationStack {
            form
                .navigationTitle((editingProject != nil) ? "Editing Project" : "Add Project")
                .toolbar { toolbarContent }
                .onAppear { onAppearFunc(); DispatchQueue.main.async { focus = .crewSearch } }

                
        }
    }

    // MARK: Form view
    private var form: some View {
        GlassList {
            infoSection
            crewSection
            detailsSection
            if showError {
                Text(errorMessage).foregroundColor(.red)
            }

            Button(editingProject != nil ? "Update Project" : "Add Project") {
                savingConditions()
            }
            .foregroundStyle(Color.accentColor)
        }
    }

    private var infoSection: some View {
        Section(header: Text("Project Info")) {
            TextField("Project Name *", text: $project.projectName)
            TextField("Project description *", text: $project.comments)
            checklist
        }
    }

    // MARK: Checklist
    private var checklist: some View {
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

    private var checklistList: some View {
        ForEach(project.checklist) { item in
            HStack {
                Image(systemName: "minus.circle.fill")
                    .symbolRenderingMode(.multicolor)
                    .foregroundColor(.red)
                    .onTapGesture { removeChecklistItem(id: item.id) }
                Text(item.text).foregroundColor(.primary)
            }
            .padding(.vertical, 4)
        }
    }

    private var crewSection: some View {
        UserSearchAddField(
            exclude: .constant(project.crew),
            selectedEntities: $selectedEntities,
            showAddedCrewList: true
        )
    }


    // MARK: Details
    private var detailsSection: some View {
        Section(header: Text("Details")) {
            colorPicker.buttonStyle(.plain)
            DatePicker("Start Date *", selection: $project.startDate, displayedComponents: .date)
            DatePicker("Finish Date *", selection: $project.finishDate, displayedComponents: .date)
            Toggle("Active", isOn: $project.active)
        }
    }

    private var colorPicker: some View {
        Menu {
            ForEach(colorsStringArray, id: \.self) { colorName in
                colorPickerButton(for: colorName)
            }
        } label: { menuLabel }
    }

    private var menuLabel: some View {
        HStack {
            Text("Color *")
            Spacer()
            if project.color.isEmpty {
                HStack {
                    Text("Select a color")
                    Image(systemName: "chevron.up.chevron.down").foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Text(project.color.capitalized)
                    Circle()
                        .fill(ProjectColorHelper.color(for: project.color))
                        .frame(width: 20, height: 20)
                    Image(systemName: "chevron.up.chevron.down").foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .foregroundStyle(Color.accentColor)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(editingProject != nil ? "Update" : "Add") { savingConditions() }
                .foregroundStyle(Color.accentColor)
        }
    }

    // MARK: Functions
    @ViewBuilder
    private func colorPickerButton(for colorName: String) -> some View {
        Button { project.color = colorName } label: { colorPickerLabel(for: colorName) }
    }

    @ViewBuilder
    private func colorPickerLabel(for colorName: String) -> some View {
        HStack {
            Text(colorName.capitalized)
            Spacer()
            Circle()
                .fill(ProjectColorHelper.color(for: colorName))
                .frame(width: 20, height: 20)
        }
    }

    private func savingConditions() {
        if project.projectName.isEmpty || project.owner.isEmpty || project.comments.isEmpty || project.color.isEmpty {
            showError = true
            errorMessage = "Please fill all required fields."
        } else if isProjectNameUsed {
            showError = true
            errorMessage = "Project name already exists."
        } else {
            showError = false
            errorMessage = ""
            if editingProject != nil {
                updateProject()
            } else {
                addProject()
            }
        }
    }

    // Saves / Adds project to Firebase Firestore
    private func addProject() {
        project.checklist = project.checklist.map { ChecklistItem(text: $0.text, isChecked: false) }
        let user = Auth.auth().currentUser
        if project.owner == user?.displayName ?? "" {
            project.owner = user?.uid ?? ""
        }
        project.crew = selectedEntities
        Task { await projectViewModel.addProject(project) }
        notifyNewCrewConnectionsIfNeeded(originalCrew: originalCrew)
        dismiss()
    }

    // Runs on appear
    private func onAppearFunc() {
        if let crew = editingProject?.crew {
            originalCrew = crew
        } else {
            originalCrew = project.crew
        }
        // Prefill selectedEntities with existing crew (users/teams as stored)
        let crew = editingProject?.crew ?? project.crew
        selectedEntities = crew
    }

    // Send invite notifications to newly added crew
    private func notifyNewCrewConnectionsIfNeeded(originalCrew: [String: String]) {
        // Newly added entries that are users (ignore teams for direct user notifications)
        let addedUserIds = project.crew
            .filter { $0.value == "user" && originalCrew[$0.key] == nil }
            .map { $0.key }
        for uid in addedUserIds {
            let newNotification = NotificationModel(
                title: "Invite to project",
                message: "\(userViewModel.user?.name ?? Auth.auth().currentUser?.displayName ?? "Someone") invited you to their project.",
                timestamp: Date(),
                recipientUID: [uid],
                fromUID: userViewModel.user?.uid ?? Auth.auth().currentUser?.uid ?? "",
                isRead: false,
                type: .connectInvite,
                relatedId: editingProject?.documentId ?? ""
            )
            notificationsViewModel.getFcmByUid(uid: uid, notification: newNotification)
        }
    }

    // Update existing project
    private func updateProject() {
        if let editingProject = editingProject {
            project.crew = selectedEntities
            Task { await projectViewModel.updateProject(documentId: editingProject.documentId, with: project) }
            notifyNewCrewConnectionsIfNeeded(originalCrew: originalCrew)
            dismiss()
        }
    }

    // Checklist ops
    private func removeChecklistItem(id: UUID) {
        project.checklist.removeAll { $0.id == id }
    }

    private func addChecklistRow() {
        let trimmedItem = newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedItem.isEmpty {
            let newItem = ChecklistItem(text: trimmedItem, isChecked: false)
            var updatedChecklist = project.checklist
            updatedChecklist.append(newItem)
            project.checklist = updatedChecklist
            newChecklistItem = ""
        }
    }

//    // Crew ops
//    private func removeUserFromCrew(_ uid: String) {
//        if let index = project.crew.firstIndex(of: uid) {
//            project.crew.remove(at: index)
//        }
//    }

    // Check if project name is used
    private var isProjectNameUsed: Bool {
        let trimmedName = project.projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        // If editing, ignore the current project's name
        return projectViewModel.projects.contains {
            $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame && $0.documentId != editingProject?.documentId
        }
    }
}

#Preview {
    NavigationStack {
        AddProjectView()
            .environmentObject(UserViewModel())
            .environmentObject(SearchUserViewModel())
            .environmentObject(ProjectViewModel())
            .environmentObject(NotificationsViewModel())
    }
}
