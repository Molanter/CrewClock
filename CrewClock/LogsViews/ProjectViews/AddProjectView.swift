//
//  AddProjectView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/4/25.
//

import SwiftUI
import FirebaseAuth

struct AddProjectView: View {
    @StateObject private var projectViewModel = ProjectViewModel()

    @Binding var showAddProjectSheet: Bool

    let user = Auth.auth().currentUser!
    @State private var project: ProjectModel
    @State private var showError = false

    init(showAddProjectSheet: Binding<Bool>) {
        self._showAddProjectSheet = showAddProjectSheet
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddProjectSheet = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addProject()
                    }
                }
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
            
            Button("Add Project") {
                addProject()
            }
        }
    }
    
    private var infoSection: some View {
        Section(header: Text("Project Info")) {
            TextField("Project Name", text: $project.projectName)
            TextField("Comments", text: $project.comments)
            //                    TextField("Checklist Items (comma-separated)", text: $project.checklist)
        }
    }
    
    private var crewSection: some View {
        Section(header: Text("Crew")) {
            TextField("Owner", text: $project.owner)
            //                    TextField("Crew (comma-separated)", text: $project.crew)
            
        }
    }
        
    private var detailsSection: some View {
        Section(header: Text("Details")) {
            TextField("Color", text: $project.color)
            DatePicker("Start Date", selection: $project.startDate, displayedComponents: .date)
            DatePicker("Finish Date", selection: $project.finishDate, displayedComponents: .date)
            Toggle("Active", isOn: $project.active)
        }
    }
    
    private func addProject() {
        if project.projectName.isEmpty || project.owner.isEmpty || /*project.crew.isEmpty || project.checklist.isEmpty ||*/ project.comments.isEmpty || project.color.isEmpty {
            showError = true
        } else {
            let user = Auth.auth().currentUser
            if project.owner == user?.displayName ?? "" {
                project.owner = user?.uid ?? ""
            }
            showError = false
            showAddProjectSheet = false
            projectViewModel.addProject(project)
        }
    }
}

#Preview {
    AddProjectView(showAddProjectSheet: .constant(false))
}
