//
//  ProjectSelectorView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/6/25.
//

import SwiftUI

struct ProjectSelectorView: View {
    @Binding var error: String?
    @Binding var text: String
    @EnvironmentObject var projectVM: ProjectViewModel

    var projects: [ProjectFB] {
        projectVM.projects
    }

    var activeProjects: [ProjectFB] {
        projectVM.projects.filter { $0.active }
    }

    var inactiveProjects: [ProjectFB] {
        projectVM.projects.filter { !$0.active }
    }

    private var selectedProject: ProjectFB? {
        projects.first { $0.name == text }
    }

    var body: some View {
        Menu {
            activeProjectsSection
            inactiveProjectsSection
        } label: {
            label
        }
        .onAppear {
            projectVM.fetchProjects()
        }
    }
    
    private var activeProjectsSection: some View {
        Section(header: Text("Active Projects")) {
            ForEach(activeProjects) { project in
                Button {
                    text = project.name
                    self.error = nil
                } label: {
                    Text(project.name)
                }
            }
        }
    }
    
    private var inactiveProjectsSection: some View {
        Menu {
            ForEach(inactiveProjects) { project in
                Button {
                    text = project.name
                    self.error = nil
                } label: {
                    Text(project.name)
                }
            }
        } label: {
            Text("Inactive Projects")
        }
    }
    
    private var label: some View {
        HStack {
            Text(displayName())
                .font(.callout)
                .lineLimit(1)
            Image(systemName: "chevron.down")
        }
        .foregroundStyle(((error?.isEmpty) != nil) ? Color.red : projectColor())
        .padding(7)
        .background {
            background
        }
    }
    
    private var background: some View {
        RoundedRectangle(cornerRadius: K.UI.cornerRadius)
            .fill(projectColor())
            .opacity(K.UI.opacity)
    }

    private func displayName() -> String {
        if let error, !error.isEmpty {
            return error.capitalized
        } else {
            return text.isEmpty ? "No project" : text
        }
    }

    private func projectColor() -> Color {
        return ProjectColorHelper.color(for: selectedProject?.color)
    }
}


//#Preview {
//    ProjectSelectorView(error: .constant(nil), text: .constant(""))
//}
