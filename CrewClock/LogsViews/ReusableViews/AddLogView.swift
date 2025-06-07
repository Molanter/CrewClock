//
//  AddLogView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/4/25.
//

import SwiftUI

struct AddLogView: View {
    @StateObject private var logsViewModel = LogsViewModel()

    @FocusState private var focusedField: Field?
    
    @Binding var showAddLogSheet: Bool

    @State private var log: LogModel = .init()
    @State private var showError = false
    @State private var expensesText: String = ""

    enum Field: Hashable {
        case name, comment, timeStarted, timeFinished, crewUID, expenses
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Log Info")) {
                    TextField("Name", text: $log.projectName)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .comment }

                    TextField("Comment", text: $log.comment)
                        .focused($focusedField, equals: .comment)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .timeStarted }

                    DatePicker("Date", selection: $log.date, displayedComponents: .date)

                    DatePicker("Time Started", selection: $log.timeStarted, displayedComponents: .hourAndMinute)

                    DatePicker("Time Finished", selection: $log.timeFinished, displayedComponents: .hourAndMinute)

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

                if showError {
                    Text("Please fill in all fields.")
                        .foregroundColor(.red)
                }

                Button("Submit") {
                    if log.projectName.isEmpty ||
                        log.timeStarted == Date.distantPast ||
                        log.timeFinished == Date.distantPast {
                        showError = true
                    } else {
                        showError = false
                        logsViewModel.addLog(log)
                        showAddLogSheet = false
                    }
                }
            }
            .navigationTitle("Add Log")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddLogSheet = false
                    }
                }
            }
        }
    }
}

//#Preview {
//    AddLogView()
//}
