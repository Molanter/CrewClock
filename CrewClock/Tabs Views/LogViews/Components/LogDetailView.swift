//
//  LogDetailView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/28/25.
//

import SwiftUI

struct LogDetailView: View {
    let logId: String
    @StateObject private var vm = LogDetailViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Loading…")
            } else if let err = vm.error {
                errorView(errorMessage: err)
            } else if let log = vm.log {
                detailsList(log: log)
            } else {
                Text("No data")
            }
        }
        .onAppear { if vm.log == nil { vm.fetch(logId: logId) } }
        .hideTabBarWhileActive("log")
    }
    
    @ViewBuilder
    private func detailsList(log: LogFB) -> some View {
        GlassList {
            infoSection(log: log)
            timesSection(log: log)
            crewSection(log: log)
            trackingSection(log: log)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Log Details")
    }
    
    @ViewBuilder
    private func infoSection(log: LogFB) -> some View {
        Section("Info") {
            LabeledContent("Name", value: log.projectName.isEmpty ? "—" : log.projectName)
            LabeledContent("Comment", value: log.comment.isEmpty ? "—" : log.comment)
            LabeledContent("Expenses", value: currencyFormatter.string(from: .init(value: log.expenses)) ?? "$0.00")

        }
    }
    
    @ViewBuilder
    private func timesSection(log: LogFB) -> some View {
        Section("Times") {
            LabeledContent("Date", value: dateFormatter.string(from: log.date))
            LabeledContent("Start", value: timeFormatter.string(from: log.timeStarted))
            LabeledContent("Finish", value: timeFormatter.string(from: log.timeFinished))
            LabeledContent("Duration", value: durationString(from: log.timeStarted, to: log.timeFinished))
        }
    }
    
    @ViewBuilder
    private func crewSection(log: LogFB) -> some View {
        Section("Crew") {
            if log.crewUID.isEmpty {
                Text("No crew assigned")
            } else {
                ForEach(log.crewUID.sorted(by: { $0.key < $1.key }), id: \.key) { uid, kind in
                    LabeledContent(uid, value: kind)
                }
            }
        }
    }
    
    @ViewBuilder
    private func trackingSection(log: LogFB) -> some View {
        Section("Tracking") {
            LabeledContent("Spreadsheet ID", value: log.spreadsheetId.isEmpty ? "—" : log.spreadsheetId)
            LabeledContent("Row", value: "\(log.row)")
            LabeledContent("Document ID", value: log.documentID)
        }
    }
    
    @ViewBuilder
    private func errorView(errorMessage err: String) -> some View {
        VStack(spacing: 8) {
            Text("Error").font(.headline)
            Text(err).font(.subheadline)
            Button("Retry") { vm.fetch(logId: logId) }
        }
    }
}

// MARK: - Formatters and helpers

private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
}()

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .none
    f.timeStyle = .short
    return f
}()

private let currencyFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .currency
    return f
}()

private func durationString(from start: Date, to end: Date) -> String {
    let seconds = max(0, end.timeIntervalSince(start))
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    if hours > 0 { return "\(hours)h \(minutes)m" }
    return "\(minutes)m"
}


// MARK: - Preview
#Preview {
    LogDetailView(logId: "exampleLogId")
}
