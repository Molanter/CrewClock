//
//  AddProjectView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/4/25.
//

import SwiftUI
import FirebaseAuth

struct AddProjectView: View {
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var searchUserViewModel: SearchUserViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @Environment(\.dismiss) private var dismiss

    var editingProject: ProjectFB?

    let user = Auth.auth().currentUser!
    private let colorsStringArray: [String] = ["blue", "yellow", "orange", "cyan", "red", "green", "mint", "purple", "pink", "indigo", "brown"]
    
    @State private var project: ProjectModel
    @State private var showError = false
    @State private var newChecklistItem: String = ""
    @State private var errorMessage: String = ""
    @State private var crewSearch: String = ""
    @State private var originalCrew: [String] = []

    //MARK: init
    init(editingProject: ProjectFB? = nil) {
        self.editingProject = editingProject
        let user = Auth.auth().currentUser
        if let editing = editingProject {
            _project = State(initialValue: ProjectModel(
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
            _project = State(initialValue: ProjectModel(
                projectName: "",
                owner: user?.uid ?? "",
                crew: [],
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
        NavigationView {
            form
            .navigationTitle("Add Project")
            .toolbar {
                toolbarContent
            }
            .onAppear {
                onAppearFunc()
            }
        }
    }
    //MARK: Form var view
    private var form: some View {
        Form {
            infoSection
            crewSection
            detailsSection
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
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
    
    //MARK: Checklist
    private var checklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Add checklist item", text: $newChecklistItem)
                    .onSubmit {
                        addChecklistRow()
                    }
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
                    .onTapGesture {
                        removeChecklistItem(id: item.id)
                    }
                Text(item.text)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 4)
        }
    }

    
    private var crewSection: some View {
        Section(header: Text("Crew")) {
            UserRowView(uid: project.owner)
            if !project.crew.isEmpty {
                crewList
            }
            TextField("Search to add crew", text: $crewSearch)
                .onChange(of: crewSearch) { oldValue, newValue in
                    searchUserViewModel.searchUsers(with: newValue)
                }
            
            if !crewSearch.isEmpty {
                crewSearchingView
            }
        }
    }
    
    //MARK: Crew searchfield
    private var crewSearchingView: some View {
        // current user id
        let me = userViewModel.user?.uid

        // sets for fast membership checks
        let connectionSet = Set(userViewModel.user?.connections ?? [])
        let crewSet       = Set(project.crew)

        // results: in my connections, not already in crew, and not me
        let results = searchUserViewModel.foundUIDs.filter {
            $0 != me && connectionSet.contains($0) && !crewSet.contains($0)
        }

        return VStack(alignment: .leading) {
            if results.isEmpty {
                Text("No connections found.").foregroundColor(.secondary)
            } else {
                ForEach(results, id: \.self) { uid in
                    HStack {
                        UserRowView(uid: uid)
                        Spacer()
                        Button("Add") {
                            crewSearch = ""
                            project.crew.append(uid)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    //MARK: Crew list
    private var crewList: some View {
        ForEach(project.crew, id: \.self) { uid in
            HStack {
                Button(action: {
                    removeUserFromCrew(uid)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .foregroundColor(.red)
                }

                UserRowView(uid: uid)
            }
        }
    }
    
    //MARK: Dates
    private var detailsSection: some View {
        Section(header: Text("Details")) {
            colorPicker
                .buttonStyle(.plain)
            DatePicker("Start Date *", selection: $project.startDate, displayedComponents: .date)
            DatePicker("Finish Date *", selection: $project.finishDate, displayedComponents: .date)
            Toggle("Active", isOn: $project.active)
        }
    }
    
    //MARK: Color picker
    private var colorPicker: some View {
        Menu {
            ForEach(colorsStringArray, id: \.self) { colorName in
                colorPickerButton(for: colorName)
            }
        } label: {
            menuLabel
        }
    }
    
    private var menuLabel: some View {
        HStack {
            Text("Color *")
            Spacer()
            if project.color.isEmpty{
                HStack {
                    Text("Select a color")
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                }
            }else {
                HStack {
                    Text(project.color.capitalized)
                    Circle()
                        .fill(ProjectColorHelper.color(for: project.color))
                        .frame(width: 20, height: 20)
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    ///Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
            .foregroundStyle(Color.accentColor)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(editingProject != nil ? "Update" : "Add") {
                savingConditions()
            }
            .foregroundStyle(Color.accentColor)
        }
    }
    
    
    //MARK: Functions
    ///ColorPicker Button
    @ViewBuilder
    private func colorPickerButton(for colorName: String) -> some View {
        Button {
            project.color = colorName
        } label: {
            colorPickerLabel(for: colorName)
        }
    }
    
    ///ColorPicker Button label
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
            
        }else if isProjectNameUsed {
            showError = true
            errorMessage = "Project name already exists."
        }else {
            showError = false
            errorMessage = ""
            if editingProject != nil {
                updateProject()
            } else {
                addProject()
            }
        }
    }
    
    ///Saves / Adds project to Firebase Firestore
    private func addProject() {
        project.checklist = project.checklist.map { ChecklistItem(text: $0.text, isChecked: false) }
        let user = Auth.auth().currentUser
        if project.owner == user?.displayName ?? "" {
            project.owner = user?.uid ?? ""
        }
        projectViewModel.addProject(project)
        notifyNewCrewConnectionsIfNeeded(originalCrew: originalCrew)
        dismiss()
    }
    
    /// func that runs on Appear
    private func onAppearFunc() {
        if let crew = editingProject?.crew {
            originalCrew = crew
        }else {
            originalCrew = project.crew
        }
        ///if editingProject exist, changes view to editing mode
//        if let editingProject = editingProject {
//            project = ProjectModel(
//                projectName: editingProject.name,
//                owner: editingProject.owner,
//                crew: editingProject.crew,
//                checklist: editingProject.checklist,
//                comments: editingProject.comments,
//                color: editingProject.color,
//                startDate: editingProject.startDate,
//                finishDate: editingProject.finishDate,
//                active: editingProject.active
//            )
//        }
    }
    
    ///Check if crew changed and send invite notification if needed
    private func notifyNewCrewConnectionsIfNeeded(originalCrew: [String]) {
        let addedCrew = project.crew.filter { !originalCrew.contains($0) }
        for uid in addedCrew {
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

    ///Save updated project to Firebase Firestore
    private func updateProject() {
        if let editingProject = editingProject {
            projectViewModel.updateProject(documentId: editingProject.documentId, with: project)
            notifyNewCrewConnectionsIfNeeded(originalCrew: originalCrew)
            dismiss()
        }
    }
    
    ///Remove checklist Item from project.checklist
    private func removeChecklistItem(id: UUID) {
        project.checklist.removeAll { $0.id == id }
        print(project.checklist)
    }
    
    ///Add checklist Item to project.checlist
    private func addChecklistRow() {
        let trimmedItem = newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedItem.isEmpty {
            let newItem = ChecklistItem(text: trimmedItem, isChecked: false)
            var updatedChecklist = project.checklist
            updatedChecklist.append(newItem)
            project.checklist = updatedChecklist
            newChecklistItem = ""
            print(project.checklist)
        }
    }
    
    ///Delete Crew's uid from project.crew array
    private func removeUserFromCrew(_ uid: String) {
        if let index = project.crew.firstIndex(of: uid) {
            project.crew.remove(at: index)
        }
    }
    
    ///check if project name is used
    private var isProjectNameUsed: Bool {
        let trimmedName = project.projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        // If editing, ignore the current project's name
        return projectViewModel.projects.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame && $0.documentId != editingProject?.documentId })
    }
}

#Preview {
    AddProjectView()
        .environmentObject(UserViewModel())
        .environmentObject(SearchUserViewModel())
        .environmentObject(ProjectViewModel())
}
