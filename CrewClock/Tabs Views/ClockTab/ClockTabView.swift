//
//  ClockTabView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/6/25.
//
//
//  ClockTabView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/6/25.
//
import SwiftUI

struct ClockTabView: View {
    @State private var showAddProject = false
    @State private var showAddLog = false
    @State private var showAddTask = false
    @State private var showProjectsSheet = false

    /// Main Clock tab layout: focuses on tasks and provides quick access to projects/log/task creation.
    var body: some View {
        NavigationStack {
            TasksView()
                .toolbar {
                    // Folder button to open Projects sheet
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showProjectsSheet.toggle()
                        } label: {
                            Image(systemName: "folder")
                        }
                        .tint(.primary)
                    }

                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(placement: .topBarTrailing)
                    }

                    // Plus menu for creating new items (project, log, task)
                    ToolbarItem(placement: .topBarTrailing) {
                        toolbarMenu
                            .foregroundStyle(.primary)
                    }
                }
        }
        .tint(K.Colors.accent)
        // Sheet for browsing all active projects from the folder toolbar button.
        .sheet(isPresented: $showProjectsSheet) {
            NavigationStack {
                ProjectsTableView()
                    .navigationTitle("Projects")
            }
            .tint(K.Colors.accent)
            .presentationDetents([.medium, .large])
        }
        // Sheet for creating a new project.
        .sheet(isPresented: $showAddProject) {
            AddProjectView()
                .tint(K.Colors.accent)
                .presentationDetents([.medium, .large])
        }
        // Sheet for creating a new log.
        .sheet(isPresented: $showAddLog) {
            AddLogView(showAddLogSheet: $showAddLog)
                .tint(K.Colors.accent)
                .presentationDetents([.medium, .large])
        }
        // Sheet for creating a new task.
        .sheet(isPresented: $showAddTask) {
            AddTaskView()
                .tint(K.Colors.accent)
                .presentationDetents([.medium, .large])
        }
    }

    private var toolbarMenu: some View {
        Menu {
            Button {
                showAddProject.toggle()
            } label: {
                Label("Add Project", systemImage: "folder.badge.plus")
            }
            Button {
                showAddLog.toggle()
            } label: {
                Label("Add Log", systemImage: "document.badge.plus")
            }
            Button {
                showAddTask.toggle()
            } label: {
                Label("Add Task", systemImage: "checkmark.circle.badge.plus")
            }
        } label: {
            Image(systemName: "plus")
        }
    }
}

#Preview {
    ClockTabView()
}
