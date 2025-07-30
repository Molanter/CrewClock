//
//  ClockTabView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/6/25.
//

import SwiftUI

struct ClockTabView: View {
    @EnvironmentObject private var projectsViewModel: ProjectViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    @Environment(\.isSearching) private var isSearching
    
    @State private var showAddProject: Bool = false
    
    var activeProjects: [ProjectFB] {
        projectsViewModel.projects.filter { $0.active }.sorted { $0.finishDate > $1.finishDate }
    }
    
    var inactiveProjects: [ProjectFB] {
        projectsViewModel.projects.filter { !$0.active }.sorted { $0.finishDate > $1.finishDate }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isSearching {
                    ClockSearchView()
                } else {
                    clock
                }
            }
            .navigationTitle("Clock")
        }
    }
    
    var clock: some View {
        ZStack(alignment: .bottom) {
            list
//            WorkingFooterView()
        }
        .frame(maxHeight: .infinity)
        .sheet(isPresented: $showAddProject) {
            AddProjectView()
                .tint(K.Colors.accent)
        }
    }
    
    private var list: some View {
        List {
            controlsSection
            activeProjectsSection
            inactiveProjectsSection
            Section {
                Spacer()
                    .frame(height: 50)
                    .listRowBackground(Color.clear)
            }
        }
    }
    
    private var controlsSection: some View {
        Section {
            tableButtons
        } header: { Text("Project controls") }
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
    
    @ViewBuilder
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
    
    @ViewBuilder
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
    
    private var tableButtons: some View {
        HStack(spacing: 15) {
            button("Add Project", "folder.badge.plus", Color.green) {
                self.showAddProject.toggle()
                print("Add Project tapped")
            }
            button("", "", Color.yellow) { }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
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
                    .font(.headline)
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
    ClockTabView()
}
