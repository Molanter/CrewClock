//
//  LogCalendarRow.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/1/25.
//

import SwiftUI
import FirebaseFirestore

struct LogCalendarRow: View {
    @EnvironmentObject private var logsViewModel: LogsViewModel
    @EnvironmentObject private var projectViewModel: ProjectViewModel
    
    var log: LogFB
    var isEmpty: Bool = false
    
    @Binding var selectedProject: LogFB
    
    @State var showDeleteAlert: Bool = false
    @State var showEditSheet: Bool = false
    @State var editingLog: LogFB?
    
    private var color: Color {
        if isEmpty {
            return Color.listRow
        }else {
            if let project = projectViewModel.projects.first(where: { project in
                project.name == log.projectName
            }) {
                return ProjectColorHelper.color(for: project.color)
            }else {
                return Color.listRow
            }
        }
    }
    
    var body: some View {
        row
            .sheet(item: $editingLog) { showSheet in
                AddLogView(showAddLogSheet: $showEditSheet, editingLog: log)
            }
            .contextMenu {
                if !isEmpty {
                    NavigationLink {
                        LogDetailView(logId: self.log.id)
                    } label: {
                        Label("Info", systemImage: "info.circle.text.page")
                    }

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
                HStack(alignment: .center) {
//                    if !isEmpty {
//                        RoundedRectangle(cornerRadius: 1)
//                            .fill(color)
//                            .frame(width: 2)
//                            .offset(x: 3)
//                    }
                    headerText
                }
                .padding(K.UI.padding)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background {
            if !isEmpty {
                background
            }
        }
    }
    
    private var headerText: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text(formattedTime(log.timeStarted) + " - " + formattedTime(log.timeFinished))
                    .font(.footnote)
                    .bold()
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(formattedDate(log.date))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if !log.comment.isEmpty {
                comment
            }
            ProjectsMenuView(selected: $selectedProject)
        }
    }
    
    private var comment: some View {
        Text(log.comment)
            .font(.callout.bold())
            .foregroundStyle(.primary)
    }
    
    
//    private var footerText: some View {
//        HStack {
//            Text(formattedDate(log.date))
//                .font(.footnote)
//                .foregroundStyle(.secondary)
//            Spacer(minLength: 0)
//            
//            Text("Some place, Minnesota")
//        }
//        .font(.caption)
//        .foregroundStyle(.gray)
//        .padding(.top, 5)
//    }
    
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
    
    private var background: some View {
        Group {
            if isEmpty {
                if #available(iOS 17.0, *) {
                    RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                        .fill(BackgroundStyle().secondary)
                }else {
                    RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                        .fill(Color(uiColor: .secondarySystemBackground))
                }
            }else {
//                RoundedRectangle(cornerRadius: K.UI.cornerRadius)
//                    .fill(color)
//                    .opacity(0.2)
                TransparentBlurView(removeAllFilters: true)
                    .blur(radius: 0.5, opaque: true)
                    .background(color.opacity(0.2))
                    .cornerRadius(K.UI.cornerRadius)
                    .overlay {
                        RoundedRectangle(cornerRadius: K.UI.cornerRadius)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    }
            }
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
    LogCalendarRow(log: exampleLog, isEmpty: false, selectedProject: .constant(exampleLog))
        .environmentObject(ProjectViewModel())
        .environmentObject(LogsViewModel())
}

