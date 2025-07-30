//
//  ProjectLookView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/21/25.
//

import SwiftUI
import FirebaseFirestore

struct ProjectLookView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @EnvironmentObject private var projectViewModel: ProjectViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var newTask: String = ""
    @State var editingProject: ProjectFB?
    @State var showAddProject: Bool = false
    
    @State private var project: ProjectFB?
    let projectSelf: ProjectFB
    
    var body: some View {
        NavigationStack {
                projectView
            .navigationTitle(project?.name ?? "Project")
            .sheet(item: $editingProject, content: { project in
                AddProjectView(editingProject: project)
                    .tint(K.Colors.accent)
            })

        }
        .onAppear {
            fetchProject()
        }
        .onDisappear {
            UINavigationBar.appearance().titleTextAttributes = [
                .foregroundColor: UIColor(.white)
            ]
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .foregroundColor: UIColor(.white)
            ]
        }
    }
    
    @ViewBuilder
    private var projectView: some View {
        list
            .toolbar {
                toolbar
            }
            .onChange(of: showAddProject) { old, isPresented in
                if !isPresented {
                    fetchProject()
                }
            }
    }
    
    @ViewBuilder
    private var list: some View {
        List {
            if !(project?.checklist.isEmpty ?? true) {
                checklistSection
            }
            crewSection
            if !(project?.crew.isEmpty ?? true) {
                crewScroll
            }
            infoSection
        }
    }
    
    private var checklistSection: some View {
        Section {
            ForEach(project?.checklist ?? []) { item in
                HStack {
                    Button(action: {
                        toggleChecklistItem(item)
                    }) {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    }
                    Text(item.text)
                        .strikethrough(item.isChecked, color: ProjectColorHelper.color(for: project?.color))
                }
            }
            HStack {
                TextField("Add task", text: $newTask)
                Spacer()
                Button {
                    addChecklistItem()
                } label: {
                    if !newTask.isEmpty {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }header: {
            Text("Checklist")
//                .font(.caption)
//                .foregroundColor(.secondary)
        }
    }
    
    private var crewSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Owner:")
                    .font(.caption)
                if project != nil {
                    if let user = getUser(project?.owner ?? "") {
                        Text(user.name.capitalized)
                            .font(.headline)
                    }
                }
            }
            if !(project?.crew.isEmpty ?? true) {
                Text("Other crew:")
                    .font(.caption)
            }
        }header: {
            Text("Crew")
//                .font(.caption)
//                .foregroundColor(.secondary)
        }
    }
    
    private var crewScroll: some View {
        Section {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(project?.crew ?? [], id: \.self) { uid in
                        if let user = getUser(uid) {
                            userScrollIcon(user)
                        }
                    }
                }
                .padding(.trailing, K.UI.padding)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        .listSectionSpacing(10)
    }
    
    private var crewScrollItem: some View {
        VStack(alignment: .center) {
            Image(systemName: "person.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40)
                .cornerRadius(K.UI.cornerRadius)
                .padding(K.UI.padding)
                .background {background}
            Text("Crew Member")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .frame(width: 60)
        }
        .padding(.bottom, 5)
    }
    
    private var infoSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Comments:")
                    .font(.caption)
                Text(project?.comments ?? "")
                    .font(.body)
            }
            if let startDate = project?.startDate {
                Text("Start date: **\(startDate.formatted(date: .abbreviated, time: .omitted))**")
            }
            if let finishDate = project?.finishDate {
                Text("Finish by: **\(finishDate.formatted(date: .abbreviated, time: .omitted))**")
            }
        }header: {
            Text("Info")
//                .font(.caption)
//                .foregroundColor(.secondary)
        }
    }
   
    @ViewBuilder
    private var background: some View {
        RoundedRectangle(cornerRadius: K.UI.cornerRadius)
            .fill(Color.sheetlistRow)
//            .opacity(0.5)
//            .blur(radius: 0)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(role: .cancel) {
                dismiss()
            } label: {
                Label("Cancel", systemImage: "xmark")
            }

        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                if let project = project {
                    self.editingProject = project
                    self.showAddProject = true
                }
            }label: {
                Text("Edit")
            }
        }
    }
    
    @ViewBuilder
    private func userScrollIcon(_ user: UserFB) -> some View {
        VStack(alignment: .center) {
            profileImage(user.profileImage)
            if let firstLetter = user.name.split(separator: " ").first?.prefix(1),
               let secondLetter = user.name.split(separator: " ").dropFirst().first?.prefix(1) {
                Text("\(firstLetter)\(secondLetter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .frame(width: 50)
            } else if let firstLetter = user.name.first {
                Text(String(firstLetter))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .frame(width: 50)
            }
        }
        .padding(K.UI.padding)
        .background {
            background
        }
        .padding(.bottom, 5)
    }
    
    @ViewBuilder
    private func profileImage(_ profileImage: String) -> some View {
        Group {
            if profileImage.isEmpty {
                Image(systemName: "person.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
                    .padding(K.UI.padding)
                    .background { background }
            } else {
                UserProfileImage(profileImage)
                .frame(width: 40)
                .cornerRadius(K.UI.cornerRadius - 8)
            }
        }
    }
    
    private func fetchProject() {
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(ProjectColorHelper.color(for: projectSelf.color))
        ]
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(ProjectColorHelper.color(for: projectSelf.color))
        ]
        projectViewModel.fetchProject(by: projectSelf.id) { fetchedProject in
            DispatchQueue.main.async {
                self.project = fetchedProject
                if let project = self.project {
                    userViewModel.fetchUser(by: project.owner)
                    for uid in project.crew {
                        userViewModel.fetchUser(by: uid)
                    }
                }
            }
        }
    }
    
    private func getUser(_ uid: String) -> UserFB? {
        userViewModel.getUser(uid)
    }
    
    private func toggleChecklistItem(_ item: ChecklistItem) {
        print("Toggling checklist item: \(item.text)")
        var updatedChecklist = project?.checklist ?? []
        if let index = updatedChecklist.firstIndex(where: { $0.id == item.id }),
           let documentId = project?.documentId {
            updatedChecklist[index].isChecked.toggle()
            projectViewModel.updateChecklist(documentId: documentId, checklist: updatedChecklist)
            fetchProject()
        }
    }
    
    private func addChecklistItem() {
        print("Adding new checklist item: \(newTask)")
        guard !newTask.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        if var checklist = project?.checklist,
           let documentId = project?.documentId {
            print("if let worked: =+")
            let newItem = ChecklistItem(text: newTask.trimmingCharacters(in: .whitespaces))
            checklist.append(newItem)
            newTask = ""
            projectViewModel.updateChecklist(documentId: documentId, checklist: checklist)
        }
    }
    
}


//    .listRowBackground(Color.listRow.opacity(0.5).blur(radius: 0))


#Preview {
    let sampleProject = ProjectFB(
        data: [
            "projectName": "Sample Project",
            "owner": "Edgars Yarmolatiy",
            "crew": ["v51yL1dwlQWFCAGfMWPuvpVUUXl1"],
            "checklist": [:],
            "comments": "Sample project comments",
            "color": "blue",
            "startDate": Timestamp(date: Date()),
            "finishDate": Timestamp(date: Date().addingTimeInterval(60 * 60 * 8)),
            "active": true
        ],
        documentId: "sampleID"
    )
    ProjectLookView(projectSelf: sampleProject)
        .environmentObject(UserViewModel())
        .environmentObject(ProjectViewModel())
}
