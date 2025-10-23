//
//  TaskDetailView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/15/25.
//


import SwiftUI
import FirebaseFirestore

struct TaskDetailView: View {
    @EnvironmentObject var publishedVars: PublishedVariebles

    let taskId: String

    @EnvironmentObject var vm: TaskViewModel

    @State private var task: TaskModel?
    @State private var isLoading = true
    @State private var loadError: String?

    @State private var saving = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if let task {
                list(for: task)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                    Text(loadError ?? "Task not found.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .navigationTitle(task?.title ?? "Task")
        .toolbar { toolbar }
        .onAppear { appearFunc() }
        .onDisappear { disappearFunc() }
    }
    
    private func list(for task: TaskModel) -> some View {
        GlassList {
            infoSection(task)
            if let crewUids = task.assigneeUIDs {
                crewSection(entities: crewUids)
            }
            actionsSection
        }
    }
    
    private func infoSection(_ task: TaskModel) -> some View {
        Section("Info") {
            if !task.description.isEmpty { Text(task.description) }
            if let due = task.dueAt?.dateValue() {
                LabeledContent("Due", value: due.formatted(date: .abbreviated, time: .omitted))
            }
            LabeledContent("Priority", value: task.priorityLabel.capitalized)
            LabeledContent("Status", value: task.status.capitalized)
        }
    }
    
    private var actionsSection: some View {
        Section("Actions") {
            Button("Mark Accepted") { setStatus("accepted") }
            Button("Mark Rejected") { setStatus("rejected") }
            Button("Mark Done") { setStatus("done") }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if saving {
            ToolbarItem(placement: .topBarTrailing) {
                ProgressView()
            }
        }
        if let task {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AddTaskView(existingTask: task)
                } label: {
                    Text("Edit")
                }
            }
        }
    }
    //MARK: - ViewBuilders
    @ViewBuilder
    private func crewSection(entities: [String: String]) -> some View {
        Section("Assigned to") {
            ForEach(Array(entities.keys), id: \.self) { id in
                let kind = entities[id]?.lowercased() ?? "user"
                if kind == "team" {
                    TeamRowView(teamId: id)
                } else {
                    UserRowView(uid: id)
                }
            }
        }
    }
    
    //MARK: - Functions
    private func setStatus(_ status: String) {
        saving = true
        Task {
            defer { saving = false }
            do { try await vm.setStatus(taskId: taskId, status: status) }
            catch { print("Status update failed:", error) }
        }
    }
    
    private func appearFunc() {
        publishedVars.navLink = task?.title ?? "Task"
        // Fetch on appear
        Task { await fetchTask() }
    }
    
    private func disappearFunc() {
        publishedVars.navLink = "" //show tabBar again
    }

    private func fetchTask() async {
        isLoading = true
        loadError = nil
        do {
            let snap = try await TaskModel.collection.document(taskId).getDocument()
            if snap.exists {
                do {
                    task = try snap.data(as: TaskModel.self)
                } catch {
                    loadError = "Decoding error: \(error.localizedDescription)"
                    task = nil
                }
            } else {
                loadError = "Task not found."
                task = nil
            }
        } catch {
            loadError = error.localizedDescription
            task = nil
        }
        isLoading = false
    }

}
