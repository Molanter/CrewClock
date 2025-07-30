//
//  ProjectButtonView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/11/25.
//

import SwiftUI

struct ProjectButtonView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var projectsViewModel: ProjectViewModel
    
    @State private var editingProject: ProjectFB?
    
    @State var showAddProject: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var projectToDelete: ProjectFB?
    @State var projectToOpen: ProjectFB?
    var project: ProjectFB
    
    var body: some View {
        menuButton
            .confirmationDialog("Are you sure you want to delete this project?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let project = projectToDelete {
                        projectsViewModel.deleteProject(project)
                        projectToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    projectToDelete = nil
                }
            }
            .sheet(item: $editingProject) { project in
                AddProjectView(editingProject: project)
                    .tint(K.Colors.accent)
            }
            .sheet(item: $projectToOpen) { project in
                ProjectLookView(projectSelf: project)
                    .tint(ProjectColorHelper.color(for: project.color))
            }
    }
    
    private var menuButton: some View {
        Menu {
            Text(project.name.capitalized)
            Button {
                self.projectToOpen = nil
                self.projectToOpen = project
            } label: {
                Label("Open", systemImage: "folder")
            }
            Button{
                userViewModel.clockIn(log: .init(projectName: project.name, date: Date.now, timeStarted: Date.now))
            }label: {
                Label("Clock In", systemImage: "person.fill.checkmark")
            }
            controlsButtonsSection
            Section {
                
            }
        } label: {
            button
                .buttonStyle(.plain)
        }

    }
    
    private var button: some View {
        button(project.name, "folder", ProjectColorHelper.color(for: project.color)) {
            print("Selected project: \(project.name)")
        }
        .frame(height: 100)
        .padding(.bottom, 5)
        .frame(maxWidth: .infinity)
    }
    
    private var controlsButtonsSection: some View {
        Section {
            Button {
                let newProject = ProjectModel(
                    projectName: project.name,
                    owner: project.owner,
                    crew: project.crew,
                    checklist: project.checklist,
                    comments: project.comments,
                    color: project.color,
                    startDate: project.startDate,
                    finishDate: project.finishDate,
                    active: project.active ? false : true
                )
                projectsViewModel.updateProject(documentId: project.documentId, with: newProject)
            }label: {
                Label(project.active ? "Finish project" : "Activate project", systemImage: project.active ? "flag.pattern.checkered" : "restart")
            }
            Button {
                self.editingProject = project
            }label: {
                Label("Edit", systemImage: "square.and.pencil")
            }
            Button(role: .destructive) {
                self.projectToDelete = project
                self.showDeleteConfirmation = true
            }label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func tableButtonLabel(_ text: String, _ image: String, _ color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: image)
                    .padding(10)
                    .background {
                        Circle()
                            .fill(color)
                    }
                Text(text)
                    .font(.headline)
            }
            Spacer()
        }
    }
    
    private func button(_ text: String, _ image: String, _ color: Color, _ action: @escaping () -> Void) -> some View {
    Button(action: action) {
        tableButtonLabel(text, image, color)
            .padding(10)
            .frame(height: 100)
            .background {
                RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                    .fill(Color.listRow)
            }
    }
}
}

//#Preview {
//    ProjectButtonView()
//}
