//
//  ProjectsMenuView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/2/25.
//

import SwiftUI

struct ProjectsMenuView: View {
    @Binding var selected: LogFB
    @EnvironmentObject var projectVM: ProjectViewModel
    @EnvironmentObject var logsVM: LogsViewModel

    var projects: [ProjectFB] {
        projectVM.projects
    }

    var activeProjects: [ProjectFB] {
        projectVM.projects.filter { $0.active == true }
    }

    var inactiveProjects: [ProjectFB] {
        projectVM.projects.filter { $0.active == false }
    }
    
    private var selectedProject: ProjectFB? {
        projects.first { $0.name == selected.projectName }
    }

    var body: some View {
        Menu {
            activeSection
            inactiveMenu
        } label: {
            label
        }
        .onAppear {
            projectVM.fetchProjects()
        }
    }
    
    private var activeSection: some View {
        Section(header: Text("Active Projects")) {
            ForEach(activeProjects) { project in
                Button {
                    update(with: project)
                } label: {
                    Text(project.name)
                }
            }
        }
    }
    
    private var inactiveMenu: some View {
        Menu {
            ForEach(inactiveProjects) { project in
                Button {
                    update(with: project)
                } label: {
                    Text(project.name)
                }
            }
        } label : {
            Text("Inactive Projects")
        }
    }
    
    private var label: some View {
        HStack {
            Text(name())
                .font(.callout)
                .lineLimit(1)
            Image(systemName: "chevron.down")
        }
        .foregroundStyle(color())
        .padding(7)
        .background {backGround}
    }
    
    var backGround: some View {
        RoundedRectangle(cornerRadius: K.UI.cornerRadius)
            .fill(color())
            .opacity(K.UI.opacity)
    }
    
    private func update(with project: ProjectFB) {
        print(project)
        logsVM.updateLog(log: LogModel(
            logId: selected.documentID,
            projectName: project.name,
            comment: selected.comment,
            date: selected.date,
            timeStarted: selected.timeStarted,
            timeFinished: selected.timeFinished,
            crewUID: selected.crewUID,
            expenses: selected.expenses,
            row: selected.row
        ))
        logsVM.fetchLogs()
    }
    
    private func color() -> Color {
        return ProjectColorHelper.color(for: selectedProject?.color)
    }
    
    private func name() -> String {
        return !selected.projectName.isEmpty ? selected.projectName : "No project"
    }
}

//#Preview {
//    ProjectsMenuView()
//}

    
