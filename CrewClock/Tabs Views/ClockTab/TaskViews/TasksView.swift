//
//  TasksView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/15/25.
//

import SwiftUI
import FirebaseFirestore

/// High-level tasks screen used in the Clock tab.
/// Shows multiple task lists (Assigned, Created, Due Today, All) in a horizontal TabView.
struct TasksView: View {
    @EnvironmentObject var vm: TaskViewModel
    @State private var search = ""

    var body: some View {
        taskList
            .background(Color(.systemGroupedBackground))
            .searchable(text: $search, prompt: "Search tasks")
            .onAppear { vm.startListening() }
            .onChange(of: vm.filter) { _ in vm.startListening() }
            .onDisappear { vm.stopListening() }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterPicker
                        .fixedSize()
                }
            }
    }

    /// Regular picker for task filter, shown in the leading toolbar.
    private var filterPicker: some View {
        Picker("Filter", selection: $vm.filter) {
            ForEach(TaskFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    /// A single list view using the current filter (vm.filter) and search text.
    private var taskList: some View {
        let tasks = filteredTasks

        return Group {
            if vm.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading tasks…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding()
            } else if let msg = vm.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.orange)
                    Text(msg)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 32)
            } else if tasks.isEmpty {
                emptyState
            } else {
                List(tasks) { task in
//                    if let taskId = task.id {
                        NavigationLink {
                            TaskDetailView(taskId: task.id)
                        } label: {
                            TaskRow(task: task)
                        }
//                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    /// Tasks filtered only by the current search text.
    /// The primary list filtering by type (assigned, created, etc.) is handled
    /// in the TaskViewModel via `vm.filter` and Firestore queries.
    private var filteredTasks: [TaskFB] {
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return vm.tasks }

        return vm.tasks.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.description.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// Displayed when there are no tasks for the current filter/search.
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("No tasks")
                .font(.headline)

            Text("Create a new task using the + button in the toolbar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }
}
