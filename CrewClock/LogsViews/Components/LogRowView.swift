//
//  LogRowView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/4/25.
//

import SwiftUI

struct LogRowView: View {
    @EnvironmentObject private var logsViewModel: LogsViewModel
    
    @Binding var selectedProject: LogFB
    
    @State var showEditSheet: Bool = false
    @State var editingLog: LogFB?
    @State var showDeleteAlert: Bool = false
    
    var log: LogFB
    
    var body: some View {
        element
            .sheet(item: $editingLog) { showSheet in
                AddLogView(showAddLogSheet: $showEditSheet, editingLog: log)
            }
            .actionSheet(isPresented: $showDeleteAlert) {
                ActionSheet(
                    title: Text("Delete Log"),
                    message: Text("This log will be deleted from database only. Are you sure?"),
                    buttons: [
                        .destructive(Text("Delete")) {
                            logsViewModel.deleteLog(log)
                        },
                        .cancel()
                    ]
                )
            }
    }
    
    private var element: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                textStack
                Spacer()
                ProjectsMenuView(selected: $selectedProject)

            }
            Text(log.comment)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .contextMenu {
            Button {
                self.editingLog = self.log
            }label: {
                Label("Edit", systemImage: "square.and.pencil")
            }
            Button(role: .destructive) {
                self.showDeleteAlert = true
            }label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var textStack: some View {
        VStack(alignment: .leading) {
            Text(formattedDate(log.date))
                .font(.footnote)
            Text(formattedTime(log.timeStarted) + " - " + formattedTime(log.timeFinished))
                .font(.callout)
                .bold()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: date)
            .replacingOccurrences(of: " ", with: "")
    }
}

//#Preview {
//    LogRowView()
//}
