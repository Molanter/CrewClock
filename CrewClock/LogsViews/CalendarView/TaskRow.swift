//
//  TaskRow.swift
//  CalendarScrollEffect
//
//  Created by Balaji Venkatesh on 21/05/25.
//

import SwiftUI
import FirebaseFirestore

struct TaskRow: View {
    @EnvironmentObject private var logsViewModel: LogsViewModel
    
    var log: LogFB
    var isEmpty: Bool = false
    
    @Binding var selectedProject: LogFB
    
    @State var showDeleteAlert: Bool = false
    @State var showEditSheet: Bool = false
    @State var editingLog: LogFB?
    
    var body: some View {
        row
            .sheet(item: $editingLog) { showSheet in
                AddLogView(showAddLogSheet: $showEditSheet, editingLog: log)
            }
            .contextMenu {
                if !isEmpty {
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
    private var row: some View {
        Group {
            if isEmpty {
                noLog
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 5) {
                        Text(formattedTime(log.timeStarted) + " - " + formattedTime(log.timeFinished))
                            .font(.callout)
                            .bold()
                        Spacer()
                        ProjectsMenuView(selected: $selectedProject)
                    }
                    if !log.comment.isEmpty {
                        Text(log.comment)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    HStack {
                        Text(formattedDate(log.date))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        
                        Text("Some place, Minnesota")
                    }
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.top, 5)
                }
                .lineLimit(1)
                .padding(15)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                .fill(.listRow)
                .shadow(color: .white.opacity(0.35), radius: 1)
        }
    }
    
    private var noLog: some View {
        VStack(spacing: 8) {
            Text("No Logs Found on this Day!")
            
            Text("Try Adding some New Log!")
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
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

#Preview {
    let exampleLog = LogFB(
        data: [
            "spreadsheetId": "sheet_123",
            "row": 1,
            "projectName": "Campus App Redesign",
            "comment": "Reviewed UI/UX wireframes.",
            "date": Timestamp(date: Date()),
            "timeStarted": Timestamp(date: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date())!),
            "timeFinished": Timestamp(date: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!),
            "crewUID": ["user123", "user456"],
            "expenses": 42.50
        ],
        documentId: "log_001"
    )
    TaskRow(log: exampleLog, selectedProject: .constant(exampleLog))
        .environmentObject(ProjectViewModel())
}

