//
//  TasksView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/15/25.
//


import SwiftUI
import FirebaseFirestore

struct TasksView: View {
    @StateObject private var vm = TaskViewModel()
    @State private var search = ""

    var body: some View {
        NavigationStack {
            VStack {
                Picker("", selection: $vm.filter) {
                    ForEach(TaskFilter.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                if vm.isLoading {
                    ProgressView().padding()
                }

                if let msg = vm.errorMessage {
                    Text(msg).foregroundStyle(.red).padding(.horizontal)
                }

                List(filteredTasks) { task in
                    NavigationLink {
                        TaskDetailView(task: task, vm: vm)
                    } label: {
                        TaskRow(task: task)
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $search, prompt: "Search tasks")
            }
            .navigationTitle("Tasks")
        }
        .onAppear { vm.startListening() }
        .onChange(of: vm.filter) { _ in vm.startListening() }
        .onDisappear { vm.stopListening() }
    }

    private var filteredTasks: [TaskModel] {
        guard !search.trimmingCharacters(in: .whitespaces).isEmpty else { return vm.tasks }
        return vm.tasks.filter {
            $0.title.localizedCaseInsensitiveContains(search) ||
            $0.description.localizedCaseInsensitiveContains(search)
        }
    }
}
