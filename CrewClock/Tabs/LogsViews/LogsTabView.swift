//
//  LogsTabView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/2/25.
//

import SwiftUI

struct LogsTabView: View {
    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject var logsViewModel: LogsViewModel
    @EnvironmentObject var publishedVars: PublishedVariebles

    @State var showAddLogSheet = false
    @State var showAddProjectSheet = false
    

    private var filteredLogs: [LogFB] {
        if publishedVars.searchLog.isEmpty {
            return logsViewModel.logs
                .sorted { $0.date > $1.date }
        }else {
            return logsViewModel.logs
                .sorted { $0.date > $1.date }
                .filter {
                    $0.projectName.localizedCaseInsensitiveContains(publishedVars.searchLog) ||
                    $0.comment.localizedCaseInsensitiveContains(publishedVars.searchLog)
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
                NoContentView(contentType: .noLogs)
            } else {
                view
                    .navigationTitle("Logs")
            }
        }
        .onChange(of: isSearching) { oldValue, newValue in
            print("isSearching -- ", isSearching ? "true" : "false")
        }
    }
    
    @ViewBuilder
    var view: some View {
        ZStack(alignment: .bottom) {
                list
            if !isSearching {
//                    footer
                }
            }
            .frame(maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var list: some View {
        if filteredLogs.isEmpty {
            NoContentView(contentType: .noResults)
        } else {
            List {
                ForEach(filteredLogs) { log in
                    LogRowView(selectedProject: .constant(log), log: log)
                }
                Section {
                    Spacer()
                        .frame(height: 50)
                        .listRowBackground(Color.clear)
                }
            }
            .refreshable {
                logsViewModel.fetchLogs()
            }
        }
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
