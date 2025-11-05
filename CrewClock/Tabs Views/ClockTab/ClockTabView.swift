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
    
    var title: String {
        switch self {
        case .tasks: return "Tasks"
        case .projects: return "Projects"
        }
    }
    
    var systemImage: String {
        switch self {
        case .tasks: return "checklist"
        case .projects: return "folder"
        }
    }
    
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
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .principal) {
                        toolbarSegmentPicker
                            .fixedSize()
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .principal) {
                        toolbarSegmentPicker
                            .fixedSize()
                    }
                }
            }
        }
    }
    
    private var toolbarSegmentPicker: some View {
        let items: [IconTextSegmentedPicker<WorkSection>.Item] = WorkSection.allCases.map { section in
            .init(id: section, title: section.title, systemImage: section.systemImage)
        }
        return IconTextSegmentedPicker(selection: $section, items: items)
    }
}

// MARK: - Printable titles for segments
extension WorkSection: CustomStringConvertible {
    var description: String { rawValue }
}

