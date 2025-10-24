//
//  ClockTabView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/6/25.
//

import SwiftUI

struct ClockTabView: View {
    @State private var showAddProject: Bool = false
    @State private var showAddLog: Bool = false
    @State private var showAddTask: Bool = false
    
    var body: some View {
        NavigationStack {
            WorkHubView()
                .navigationTitle("Clock")
                .toolbar { toolbar }
            
                .sheet(isPresented: $showAddProject) {
                    AddProjectView()
                        .tint(K.Colors.accent)
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showAddLog) {
                    AddLogView(showAddLogSheet: $showAddLog)
                        .tint(K.Colors.accent)
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showAddTask) {
                    AddTaskView()
                        .tint(K.Colors.accent)
                        .presentationDetents([.medium, .large])
                }
        }
    }
    
    private var toolbarMenu: some View {
        Menu {
            Button {
                self.showAddProject.toggle()
            }label: {
                Label("Add Project", systemImage: "folder.badge.plus")
            }
            Button {
                self.showAddLog.toggle()
            }label: {
                Label("Add Log", systemImage: "document.badge.plus")
            }
            Button {
                self.showAddTask.toggle()
            }label: {
                Label("Add Task", systemImage: "checkmark.circle.badge.plus")
            }
        }label: {
            Image(systemName: "plus")
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            toolbarMenu
        }
    }
}

#Preview {
    ClockTabView()
}


enum WorkSection: String, CaseIterable, Identifiable {
    case tasks = "Tasks"
    case projects = "Projects"
    var id: String { rawValue }
}

struct WorkHubView: View {
    @State private var section: WorkSection = .projects
    
    var body: some View {
        NavigationStack {
            TabView(selection: $section) {
                TasksView()
                    .tag(WorkSection.tasks)
                ProjectsTableView()
                    .tag(WorkSection.projects)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: []) // keep default safe-area behavior
            .navigationTitle(section.rawValue)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    toolbarSegmentPicker
                }
            }
        }
    }
    
    private var toolbarSegmentPicker: some View {
        SegmentedControlPicker(
            selection: $section,
            items: WorkSection.allCases,
            selectedTint: UIColor(K.Colors.accent),
            selectedText: .white,
            normalText: UIColor(K.Colors.accent)
        )
        .frame(height: 34)
    }
}

// MARK: - Printable titles for segments
extension WorkSection: CustomStringConvertible {
    var description: String { rawValue }
}
