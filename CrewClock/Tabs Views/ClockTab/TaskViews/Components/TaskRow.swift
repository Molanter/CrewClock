//
//  TaskRow.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/15/25.
//

import SwiftUI

struct TaskRow: View {
    @Environment(\.colorScheme) var colorScheme

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
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            VStack {
                Text(task.priorityLabel.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background {
                        TransparentBlurView(removeAllFilters: false)
                            .blur(radius: 5, opaque: true)
                            .background(priorityColor(priority: task.priority).opacity(0.5))
                            .overlay(
                                Capsule()
                                    .stroke(priorityColor(priority: task.priority), lineWidth: 1.5)
                            )
                    }
                    .clipShape(Capsule())
                statusPill(task.status)

            }
        }
    }
    
    private func priorityColor(priority: Int) -> Color {
        if priority == 1 {
            return .green
        }else if priority == 2 {
            return .blue
        }else if priority == 3 {
            return . yellow
        }else if priority == 4 {
            return .orange
        }else if priority == 5 {
            return .red
        }else {
            return .gray
        }
    }
    
    private func statusPill(_ status: String) -> some View {
        Text(status.capitalized)
            .font(.caption2).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
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
