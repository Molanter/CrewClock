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
    @Environment(\.dismiss) private var dismiss

    @Binding var showAddProjectSheet: Bool
    var editingProject: ProjectFB?

    let user = Auth.auth().currentUser!
    private let colorsStringArray: [String] = ["blue", "yellow", "orange", "cyan", "red", "green", "mint", "purple", "pink", "indigo", "brown"]
    
    @State private var project: ProjectModel
    @State private var showError = false
    @State private var newChecklistItem: String = ""
    @State private var crewSearch: String = ""
    
    init(showAddProjectSheet: Binding<Bool>, editingProject: ProjectFB? = nil) {
        self._showAddProjectSheet = showAddProjectSheet
        self.editingProject = editingProject
        let user = Auth.auth().currentUser
        _project = State(initialValue: ProjectModel(
            projectName: "",
            owner: user?.displayName ?? "",
            crew: [],
            checklist: [],
            comments: "",
            color: "",
            startDate: Date.now,
            finishDate: Date.now,
            active: true
        ))
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
    
    private var form: some View {
        Form {
            infoSection
            crewSection
            detailsSection
            if showError {
                Text("Please fill in all fields.")
                    .foregroundColor(.red)
            }
            
            Button(editingProject != nil ? "Update Project" : "Add Project") {
                if editingProject != nil {
                    updateProject()
                } else {
                    addProject()
                }
            }
            .foregroundStyle(Color.accentColor)
        }
    }
    
    private var infoSection: some View {
        Section(header: Text("Project Info")) {
            TextField("Project Name", text: $project.projectName)
            TextField("Comments", text: $project.comments)
            checklist
        }
    }
    
    @ViewBuilder
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
//            TextField("Search to add crew", text: $crewSearch)
            
        }
    }
        
    private var detailsSection: some View {
        Section(header: Text("Details")) {
            colorPicker
                .buttonStyle(.plain)
            DatePicker("Start Date", selection: $project.startDate, displayedComponents: .date)
            DatePicker("Finish Date", selection: $project.finishDate, displayedComponents: .date)
            Toggle("Active", isOn: $project.active)
        }
    }
    
    private var colorPicker: some View {
        Menu {
            ForEach(colorsStringArray, id: \.self) { colorName in
                Button {
                    project.color = colorName
                } label: {
                    HStack {
                        Text(colorName.capitalized)
                        Spacer()
                        Circle()
                            .fill(ProjectColorHelper.color(for: colorName))
                            .frame(width: 20, height: 20)
                    }
                }
            }
        } label: {
            menuLabel
        }
    }
    
    private var menuLabel: some View {
        HStack {
            Text("Color")
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
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                showAddProjectSheet = false
                dismiss()
            }
            .foregroundStyle(Color.accentColor)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(editingProject != nil ? "Update" : "Add") {
                if editingProject != nil {
                    updateProject()
                } else {
                    addProject()
                }
            }
            .foregroundStyle(Color.accentColor)
        }
    }
    
    private func addProject() {
        if project.projectName.isEmpty || project.owner.isEmpty/* || project.crew.isEmpty || project.checklist.isEmpty || project.comments.isEmpty || project.color.isEmpty*/ {
            showError = true
        } else {
            project.checklist = project.checklist.map { ChecklistItem(text: $0.text, isChecked: false) }
            let user = Auth.auth().currentUser
            if project.owner == user?.displayName ?? "" {
                project.owner = user?.uid ?? ""
            }
            showError = false
            showAddProjectSheet = false
            projectViewModel.addProject(project)
            dismiss()
        }
    }
    
    private func onAppearFunc() {
        showAddProjectSheet = true
        if let editingProject = editingProject {
            project = ProjectModel(
                projectName: editingProject.name,
                owner: editingProject.owner,
                crew: editingProject.crew,
                checklist: editingProject.checklist,
                comments: editingProject.comments,
                color: editingProject.color,
                startDate: editingProject.startDate,
                finishDate: editingProject.finishDate,
                active: editingProject.active
            )
        }
    }
    
    private func updateProject() {
        if project.projectName.isEmpty || project.owner.isEmpty || project.comments.isEmpty || project.color.isEmpty {
            showError = true
        } else {
            showError = false
            showAddProjectSheet = false
            if let editingProject = editingProject {
                projectViewModel.updateProject(documentId: editingProject.documentId, with: project)
                dismiss()
            }
        }
    }
    
    private func removeChecklistItem(id: UUID) {
        project.checklist.removeAll { $0.id == id }
        print(project.checklist)
    }
    
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
}

#Preview {
    AddProjectView(showAddProjectSheet: .constant(false))
}
