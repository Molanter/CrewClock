//
//  ProjectsTableView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/20/25.
//

import SwiftUI

struct ProjectsTableView: View {
    @EnvironmentObject private var projectsViewModel: ProjectViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    
//    @Binding var addProject: Bool
//    @Binding var addLog: Bool
    
    var activeProjects: [ProjectFB] {
        projectsViewModel.projects.filter { $0.active }.sorted { $0.finishDate > $1.finishDate }
    }
    
    var inactiveProjects: [ProjectFB] {
        projectsViewModel.projects.filter { !$0.active }.sorted { $0.finishDate > $1.finishDate }
    }
    
    var body: some View {
        clock
    }
    
    var clock: some View {
        ZStack(alignment: .bottom) {
            list
//            WorkingFooterView()
        }
        .frame(maxHeight: .infinity)
    }
    
    private var list: some View {
        GlassList {
//            controlsSection
            activeProjectsSection
            inactiveProjectsSection
            Section {
                Spacer()
                    .frame(height: 50)
                    .listRowBackground(Color.clear)
            }
        }
    }
    
    private var activeProjectsSection: some View {
        Section {
            if activeProjects.isEmpty {
                NoProjectsView(contentType: .noActiveProjects)
                    .listRowBackground(Color.clear)
            }else {
                activeProjectButtons
                    .buttonStyle(.plain)
                    .padding(.top, 15)
            }
        } header: { Text("Active projects") }
    }
    
    private var inactiveProjectsSection: some View {
        Section {
            if inactiveProjects.isEmpty {
                NoProjectsView(contentType: .noFinishedProjects)
                    .listRowBackground(Color.clear)
            }else {
                inactiveProjectButtons
                    .buttonStyle(.plain)
                    .padding(.top, 15)
            }
        } header: { Text("Inactive projects") }
    }
    
    private var activeProjectButtons: some View {
        // Create rows of two projects each
        ForEach(Array(stride(from: 0, to: activeProjects.count, by: 2)), id: \.self) { index in
            HStack(spacing: 15) {
                // First item in the row
                ProjectButtonView(project: activeProjects[index])
                
                // Second item if exists;
                if index + 1 < activeProjects.count {
                    ProjectButtonView(project: activeProjects[index + 1])
                }
            }
            .listRowSeparator(.hidden, edges: .all)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private var inactiveProjectButtons: some View {
        // Create rows of two projects each
        ForEach(Array(stride(from: 0, to: inactiveProjects.count, by: 2)), id: \.self) { index in
            HStack(spacing: 15) {
                // First item in the row
                ProjectButtonView(project: inactiveProjects[index])
                
                // Second item if exists; otherwise a spacer
                if index + 1 < inactiveProjects.count {
                    ProjectButtonView(project: inactiveProjects[index + 1])
                }
            }
            .listRowSeparator(.hidden, edges: .all)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    ///not used right now
    private var controlsSection: some View {
        Section {
            tableButtons
        } header: { Text("Controls") }
    }
    ///not used right now
    private var tableButtons: some View {
        HStack(spacing: 15) {
            button("Add Project", "folder.badge.plus", Color.green) {
//                self.showAddProject.toggle()
                print("Add Project tapped")
            }
            button("Add Log", "plus", Color.yellow) {
//                self.showAddLog.toggle()
            }
            button("Add Task", "checkmark.circle.badge.plus", Color.green) {
//                self.showAddTask.toggle()
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
        
    //MARK: - Functions
    
    @ViewBuilder
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
                    .font(.body)
                    .bold()
            }
            Spacer()
        }
    }
    
    @ViewBuilder
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

#Preview {
    ProjectsTableView()
}
