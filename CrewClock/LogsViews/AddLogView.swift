//
//  AddLogView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/4/25.
//

import SwiftUI
import FirebaseFirestore

struct AddLogView: View {
    @EnvironmentObject var logsViewModel: LogsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focusedField: Field?
    
    @Binding var showAddLogSheet: Bool

    @State private var log: LogModel = .init()
    @State private var showError = false
    @State private var expensesText: String = ""
    
    var editingLog: LogFB?

    enum Field: Hashable {
        case name, comment, timeStarted, timeFinished, crewUID, expenses
    }
    
    var body: some View {
        NavigationStack {
            form
            .navigationTitle( buttonLabel() )
            .toolbar { toolbarContent }
        }
    }
    
    @ViewBuilder
    private var form: some View {
        Form {
            logInfoSection
            dateTimeSection
            detailsSection
            
            if showError {
                Text("Please fill in all fields.")
                    .foregroundColor(.red)
            }

            Button(buttonLabel()) {
                buttonAction()
            }
        }
        .onAppear {
            apearFunc()
        }
    }
    
    private var logInfoSection: some View {
        Section(header: Text("Log Info")) {
            ProjectSelectorView(error: .constant(nil), text: $log.projectName)
            
            TextField("Comment", text: $log.comment)
                .focused($focusedField, equals: .comment)
                .submitLabel(.next)
                .onSubmit { focusedField = .timeStarted }
            
        }
    }
    
    
    private var dateTimeSection: some View {
        Section(header: Text("Date & Time")) {
            DatePicker("Date", selection: $log.date, displayedComponents: .date)
            
            DatePicker("Time Started", selection: $log.timeStarted, displayedComponents: .hourAndMinute)
            
            DatePicker("Time Finished", selection: $log.timeFinished, displayedComponents: .hourAndMinute)
        }

    }
    
    private var detailsSection: some View {
        Section(header: Text("Details")) {

//                    TextField("Crew UID (comma-separated)", text: $log.crewUID)
//                        .focused($focusedField, equals: .crewUID)
//                        .submitLabel(.next)
//                        .onSubmit { focusedField = .expenses }

            TextField("Expenses", text: $expensesText)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .expenses)
                .onChange(of: expensesText) { newValue in
                    // Only update log.expenses if conversion is possible
                    if let value = Double(newValue) {
                        log.expenses = value
                    } else {
                        log.expenses = 0.0
                    }
                }
                .onAppear {
                    expensesText = log.expenses == 0.0 ? "" : String(log.expenses)
                }
        }

    }
    
    private func buttonAction() {
        if editingLog != nil {
            updateLog()
        }else {
            addLog()
        }
    }
    
    private func addLog() {
        if log.projectName.isEmpty ||
            log.timeStarted == Date.distantPast ||
            log.timeFinished == Date.distantPast {
            showError = true
        } else {
            showError = false
            logsViewModel.addLog(log)
            showAddLogSheet = false
            dismiss()
        }
    }
    
    private func updateLog() {
        if log.projectName.isEmpty ||
            log.timeStarted == Date.distantPast ||
            log.timeFinished == Date.distantPast {
            showError = true
        } else {
            showError = false
            logsViewModel.updateLog(log: log)
            showAddLogSheet = false
            dismiss()
        }
    }
    
    private func buttonLabel() -> String {
        return editingLog != nil ? "Update Log" : "Add Log"
    }
    
    private func apearFunc() {
        if let editingLog = editingLog {
            log = LogModel(
                logId: editingLog.documentID,
                projectName: editingLog.projectName,
                comment: editingLog.comment,
                date: editingLog.date,
                timeStarted: editingLog.timeStarted,
                timeFinished: editingLog.timeFinished,
                crewUID: editingLog.crewUID,
                expenses: editingLog.expenses
            )
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                showAddLogSheet = false
                dismiss()
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(buttonLabel()) {
                buttonAction()
            }
        }
    }
}

//#Preview {
//    AddLogView()
//}
