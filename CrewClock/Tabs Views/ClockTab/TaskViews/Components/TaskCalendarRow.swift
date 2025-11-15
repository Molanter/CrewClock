//
//  TaskCalendarRow.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 11/15/25.
//
import SwiftUI
import FirebaseFirestore

struct TaskCalendarRow: View {
    let task: TaskFB
    
    var body: some View {
        NavigationLink {
            TaskDetailView(taskId: task.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Time row
                HStack {
                    Text(timeLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(dateLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Title
                if task.title.isEmpty {
                    Text("Untitled task")
                        .font(.headline)
                        .lineLimit(1)
                }else {
                    HStack {
                        Text("Task: ")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text(task.title)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }

                // Assigned user profile images
                if !task.assigneeUserUIDs.isEmpty {
//                    UserAvatarStackRow(uids: task.assigneeUserUIDs, size: 32, overlap: 5)
//                        .padding(.top, 4)
                    AssigneeStatusScrollView(task: task, size: 40, spacing: 10)
                }
            }
            .padding([.horizontal, .top], K.UI.padding)
            .padding(.bottom, K.UI.padding/2)
            .background(
                RoundedRectangle(cornerRadius: K.UI.cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .stroke(Color.primary.opacity(0.5), lineWidth: 1)
                    .shadow(color: Color.primary.opacity(0.15), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var statusInfo: (text: String, icon: String) {
        let status = task.status.lowercased()
        switch status {
        case "done":
            return ("Completed", "checkmark.circle.fill")
        case "inprogress", "in progress":
            return ("In progress", "clock.fill")
        default:
            let text = status.capitalized.isEmpty ? "Open" : status.capitalized
            return (text, "circle.dashed")
        }
    }
    
    private var statusText: String { statusInfo.text }
    private var statusIcon: String { statusInfo.icon }
    
    private var dateLabel: String {
        if let start = task.scheduledStartAt {
            return start.formatted(date: .abbreviated, time: .omitted)
        } else if let due = task.dueAt {
            return due.formatted(date: .abbreviated, time: .omitted)
        }
        return ""
    }

    private var timeLabel: String {
        if let start = task.scheduledStartAt {
            return start.formatted(date: .omitted, time: .shortened)
        } else if let due = task.dueAt {
            return due.formatted(date: .omitted, time: .shortened)
        }
        return ""
    }
}

