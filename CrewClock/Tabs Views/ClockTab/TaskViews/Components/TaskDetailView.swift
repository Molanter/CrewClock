//
//  TaskDetailView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/15/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TaskDetailView: View {
    @EnvironmentObject var publishedVars: PublishedVariebles

    let taskId: String

    @EnvironmentObject var vm: TaskViewModel

    @State private var task: TaskFB?
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
    
    private func list(for task: TaskFB) -> some View {
        GlassList {
            infoSection(task)
            
            crewSection(task: task)
            
            actionsSection
        }
    }
    
    private func infoSection(_ task: TaskFB) -> some View {
        Section("Info") {
            if !task.description.isEmpty { Text(task.description) }
            if let due = task.dueAt {
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
    private func crewSection(task: TaskFB) -> some View {
        Section("Assigned to") {
            if task.assigneeUserUIDs.isEmpty {
                Text("No assignees")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(task.assigneeUserUIDs, id: \.self) { uid in
                    HStack {
                        UserRowView(uid: uid)

                        Spacer()

                        let rawStatus = task.assigneeStates[uid] ?? "pending"

                        let iconName: String = {
                            switch rawStatus.lowercased() {
                            case "rejected": return "xmark.circle.fill"
                            case "accepted": return "checkmark.circle.fill"
                            case "done": return "flag.checkered"
                            case "sent": return "paperplane.fill"
                            case "seen": return "eye"
                            default: return "paperplane.fill"
                            }
                        }()

                        let iconColor: Color = {
                            switch rawStatus.lowercased() {
                            case "rejected": return .red
                            case "accepted": return .green
                            case "done": return .primary
                            case "sent": return .secondary
                            case "seen": return .secondary
                            default: return .secondary
                            }
                        }()

                        Image(systemName: iconName)
                            .foregroundStyle(iconColor)
                            .font(.body)
                    }
                }
            }
        }
    }
    
    //MARK: - Functions
    private func setStatus(_ status: String) {
        saving = true
        Task {
            defer { saving = false }
            do {
                try await vm.setStatus(for: task!, status: status)
                // Reload the task so UI reflects updated assigneeStates / status
                await fetchTask()
            } catch {
                print("Status update failed:", error)
                await MainActor.run {
                    loadError = error.localizedDescription
                }
            }
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
        defer { isLoading = false }

        do {
            let snap = try await Firestore.firestore()
                .collection("tasks")
                .document(taskId)
                .getDocument()

            guard snap.exists, let data = snap.data() else {
                loadError = "Task not found."
                task = nil
                return
            }

            // Initialize TaskFB from the raw Firestore data
            task = TaskFB(data: data, documentId: snap.documentID)
            
            // If this user was in "sent" state, mark as "seen" on open
            if let me = Auth.auth().currentUser?.uid, var currentTask = task {
                if currentTask.assigneeStates[me] == "sent" {
                    currentTask.assigneeStates[me] = "seen"
                    task = currentTask
                    do {
                        try await vm.updateTask(currentTask)
                    } catch {
                        print("Failed to mark task as seen:", error)
                    }
                }
            }
        } catch {
            loadError = error.localizedDescription
            task = nil
        }
    }

}
