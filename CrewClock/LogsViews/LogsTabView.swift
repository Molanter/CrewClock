//
//  LogsTabView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/2/25.
//

import SwiftUI

struct LogsTabView: View {
    @State private var searchText = ""
    @State var showAddLogSheet = false
    @State var showAddProjectSheet = false
    
    @EnvironmentObject var logsViewModel: LogsViewModel

    private var filteredLogs: [LogFB] {
        if searchText.isEmpty {
            return logsViewModel.logs
                .sorted { $0.date > $1.date }
        }else {
            return logsViewModel.logs
                .sorted { $0.date > $1.date }
                .filter {
                $0.projectName.localizedCaseInsensitiveContains(searchText) ||
                $0.comment.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            switchView
            .toolbar { toolbarContent }
            .sheet(isPresented: $showAddLogSheet) {
                AddLogView(showAddLogSheet: $showAddLogSheet)
                    .tint(.indigo)
            }
            .sheet(isPresented: $showAddProjectSheet) {
                AddProjectView(showAddProjectSheet: $showAddProjectSheet)
                    .tint(.indigo)
            }
            .onAppear(perform: {
                logsViewModel.fetchLogs()
            })
        }
    }
    
    @ViewBuilder
    private var switchView: some View {
        ZStack {
            if logsViewModel.logs.isEmpty {
                Text("❌ No logs available.")
            } else {
                view
                    .navigationTitle("Logs")
            }
        }
    }
    
    @ViewBuilder
    var view: some View {
        ZStack(alignment: .bottom) {
                list
                footer
            }
            .frame(maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var list: some View {
        List(filteredLogs) { log in
            LogRowView(selectedProject: .constant(log), log: log)
        }
        .refreshable {
            logsViewModel.fetchLogs()
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search logs")
        .padding(.bottom, 50)
    }
    
    private var footer: some View {
        WorkingFooterView()
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                self.showAddProjectSheet.toggle()
            } label: {
                Label("add project", systemImage: "folder.badge.plus")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                self.showAddLogSheet.toggle()
            } label: {
                Label("add log", systemImage: "plus")
            }
        }
    }
}

#Preview {
    LogsTabView()
}
