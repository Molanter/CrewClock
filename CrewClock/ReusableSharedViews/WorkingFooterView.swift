//
//  WorkingFooterView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/7/25.
//

import SwiftUI

struct WorkingFooterView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var projectViewModel: ProjectViewModel
    @EnvironmentObject private var logsViewModel: LogsViewModel

    @State var project = "Select project"
    @State var showAddProject: Bool = false
    @State private var errorMessage = ""
    private var working: Bool {
        return userViewModel.user?.working ?? false
    }
    
    private var user: UserFB? {
        return userViewModel.user
    }
    
    var body: some View {
        Group {
            if projectViewModel.projects.isEmpty {
                newProject
            }else {
                footer
            }
        }
        .onAppear {
            onAppear()
        }
        .padding(.bottom, K.UI.padding)
    }
    
    private var newProject: some View {
        HStack {
            Spacer()
            Button{
                self.showAddProject.toggle()
            }label: {
                Label("Create first project", systemImage: "folder.badge.plus")
                    .padding(K.UI.padding)
                    .background {
                        RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                            .fill(K.Colors.accent)
                    }
                    .padding(K.UI.padding)
                
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background {
            backround
        }
        .sheet(isPresented: $showAddProject) {
            AddProjectView()
        }

    }
    
    private var footer: some View {
        HStack {
            if working {
                workingFooter
            }else {
                clockInFooter
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background {
            backround
        }
    }
    
    private var workingFooter: some View {
        HStack {
            workingText
            Spacer()
            controllButtonImage("stop.circle", {clockOut()})
        }
        .padding(K.UI.padding)
    }
    
    private var workingText: some View {
//        VStack(alignment: .leading) {
//            Text("Today's time: ") + Text("\(formatTime()) Clocked In")
//                .bold()
//                .font(.caption)
            HStack(alignment: .center) {
                Text("Working on: ")
                    .font(.callout)
                    .bold()
                ProjectSelectorView(text: $userViewModel.currentProjectName)
            }
            .onChange(of: userViewModel.currentProjectName) { old, newValue in
                print("project changed for footer: \(newValue)")
                userViewModel.updateUser(data: ["currentLog.projectName": newValue])
            }
//        }
    }
    
    private var clockInFooter: some View {
        HStack(alignment: .center) {
            clockInText
            Spacer()
            controllButtonImage("play.circle", {clockIn()})
        }
        .padding(K.UI.padding)
    }
    
    private var clockInText: some View {
        HStack(alignment: .center) {
            HStack {
                Text("Clock In")
                    .font(.callout)
                    .bold()
                if !errorMessage.isEmpty {
                    errorMessageLabel
                }
            }
            ProjectSelectorView(text: $project)
        }
    }
    
    private var errorMessageLabel: some View {
        Text(errorMessage)
            .font(.callout)
            .foregroundStyle(.red)
    }
    
    private var backround: some View {
        RoundedRectangle(cornerRadius: K.UI.cornerRadius)
            .fill(Color.listRow)
//            .cornerRadius(K.UI.cornerRadius, corners: [.topLeft, .topRight])
    }
    
    private func formatTime() -> String {
        var date = user?.currentLog?.timeStarted
        guard let date = date else { return "--" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        return formatter.string(from: date)
    }
    
    private func controllButtonImage(_ image: String, _ action: @escaping () -> Void) -> some View {
        return Button {
            action()
        }label: {
            Image(systemName: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 35)
//                .padding(K.UI.padding)
//                .background(Circle().fill(Color.accentColor).opacity(K.UI.opacity))
                .foregroundStyle(Color.accentColor)
        }
    }
    
    private func clockIn() {
        if self.project == "" || self.project == "Select project" {
            errorMessage = "Select Project"
        }else {
            userViewModel.clockIn(log: .init(projectName: project, date: Date.now, timeStarted: Date.now))
        }
    }
    
    private func clockOut() {
        if self.project == "" || self.project == "Select project" {
            
        }else {
            project = "Select project"
            logsViewModel.addLog(.init(projectName: user?.currentLog?.projectName ?? "No name", comment: user?.currentLog?.comment ?? "", timeStarted: user?.currentLog?.timeStarted ?? Date.now, timeFinished: Date.now, expenses: user?.currentLog?.expenses ?? 0.0))
            userViewModel.clockOut()
        }
    }
    
    private func onAppear() {
        projectViewModel.fetchProjects()
        userViewModel.fetchUser()
        if working {
            self.project = user?.currentLog?.projectName ?? ""
        }
    }
}

#Preview {
    WorkingFooterView()
        .environmentObject(ProjectViewModel())
}
