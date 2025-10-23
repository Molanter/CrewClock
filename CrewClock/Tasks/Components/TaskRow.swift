//
//  TaskRow.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/15/25.
//

import SwiftUI

struct TaskRow: View {
    let task: TaskModel
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.headline)
                HStack(spacing: 8) {
                    if let due = task.dueAt?.dateValue() {
                        Image(systemName: "calendar")
                        Text(due.formatted(date: .abbreviated, time: .omitted))
                    }
//                    if ((task.teamId) == nil) {
//                        Text("Team").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
//                            .background(Capsule().fill(.thinMaterial))
//                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            VStack {
                statusPill(task.status)
                Text(task.priorityLabel.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
            }
        }
    }
    
    private func statusPill(_ status: String) -> some View {
        Text(status.capitalized)
            .font(.caption2).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(
                Capsule().fill(statusColor(status).opacity(0.15))
            )
            .foregroundStyle(statusColor(status))
    }
    
    private func statusColor(_ s: String) -> Color {
        switch s.lowercased() {
        case "pending":  return .orange
        case "accepted": return .green
        case "rejected": return .red
        case "done", "completed": return .blue
        default: return .gray
        }
    }
}
