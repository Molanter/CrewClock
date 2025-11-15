//
//  CalendarLogsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/30/25.
//

import SwiftUI

struct CalendarLogsView: View {
    @EnvironmentObject private var logsViewModel: LogsViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentDate = Date()
    @State private var currentWeek: [Date.Day] = Date.currentWeek(from: Date())
    @State private var selectedDate: Date?
    @StateObject private var myTasksVM = MyAssignedTasksViewModel()

    // Shared pager selection (0 = prev, 1 = current, 2 = next)
    @State private var pageIndex: Int = 1

    // How long to let the TabView page animation play before snapping back
    private let pageAnimDelay: UInt64 = 320_000_000 // ~0.32s

    var body: some View {
        NavigationStack {
            page
        }
        .onAppear {
            Task {
                await myTasksVM.loadAssignedTasks()
            }
        }
    }

    private var page: some View {
        VStack {

            // Header uses shared pager selection
            CalendarHeader(
                currentDate: $currentDate,
                currentWeek: $currentWeek,
                selectedDate: $selectedDate,
                pageIndex: $pageIndex
            )

            // Logs area that slides horizontally in sync with header
            logsPager
                .background(backGroundColor())
                .overlay { OutsideGlassOverlay(radius: K.UI.cornerRadius) }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .onAppear {
            if selectedDate == nil {
                selectedDate = currentWeek.first(where: { $0.date.isSame(.now) })?.date
            }
        }
        .onChange(of: pageIndex) { _, new in
            guard new == 0 || new == 2 else { return }
            let delta = (new == 0) ? -1 : 1

            Task {
                // Let the slide animation play so the user sees the move
                try? await Task.sleep(nanoseconds: pageAnimDelay)

                shiftWeek(by: delta)

                // Snap both header and logs back to center page instantly
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) { pageIndex = 1 }
            }
        }
    }

    
    // MARK: - Sliding Logs Pager

    private var logsPager: some View {
        GeometryReader {
            let size = $0.size
            
                    
                    ScrollView(.vertical) {
                        /// Going to use the native pinned section headers to create the header effect (Saw in the intro video!)
                        LazyVStack(spacing: 15, pinnedViews: [.sectionHeaders]) {
                            ForEach(currentWeek) { day in
                                let date = day.date
                                let isLast = currentWeek.last?.id == day.id
                                
                                Section {
                                    /// Use this date value to extract tasks from your database, such as SwiftData, CoreData, etc.
                                    VStack(alignment: .leading, spacing: 15) {
                                        tasks(for: date)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.leading, 70)
                                    .padding(.top, -70)
                                    .padding(.bottom, 10)
                                    .frame(
                                        minHeight: isLast ? size.height - 110 : nil,
                                        alignment: .top
                                    )
                                } header: {
                                    VStack(spacing: 4) {
                                        Text(date.string("EEE"))
                                        Text(date.string("dd"))
                                            .font(.largeTitle.weight(.bold))
                                    }
                                    .frame(width: 55, height: 70)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .contentMargins(.all, 20, for: .scrollContent)
                    /// Only Adding, Padding vertically for the indicators
                    .contentMargins(.vertical, 20, for: .scrollIndicators)
                    /// Using Scroll Position to identify the current active section
                    .scrollPosition(id: .init(get: {
                        return currentWeek.first(where: { $0.date.isSame(selectedDate) })?.id
                    }, set: { newValue in
                        /// Converting id into selected date
                        selectedDate = currentWeek.first(where: { $0.id == newValue })?.date
                    }), anchor: .top)
                    /// Undoing the negative padding effect
                    .safeAreaPadding(.bottom, 70)
                    .padding(.bottom, -70)
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 30, style: .continuous))
        .ignoresSafeArea(.all, edges: .bottom)
    }

    // MARK: - Helpers

    private func shiftWeek(by delta: Int) {
        currentDate = Calendar.current.date(byAdding: .weekOfYear, value: delta, to: currentDate) ?? currentDate
        currentWeek = Date.currentWeek(from: currentDate)
        selectedDate = currentWeek.first?.date
    }

    // MARK: - Data helpers
    
    private func logsForDate(_ date: Date) -> [LogFB] {
        logsViewModel.logs.filter { log in
            Calendar.current.isDate(log.date, inSameDayAs: date)
        }
    }
    
    private func assignedTasks(for date: Date) -> [TaskFB] {
        myTasksVM.tasksScheduled(on: date)
    }

    @ViewBuilder
    private func tasks(for date: Date) -> some View {
        let logs = logsForDate(date)
        let tasks = assignedTasks(for: date)
        
        if logs.isEmpty && tasks.isEmpty {
            LogCalendarRow(log: K.Logs.dummyLog, isEmpty: true, selectedProject: .constant(K.Logs.dummyLog))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                // Logs for this day
                if !logs.isEmpty {
                    ForEach(logs) { log in
                        LogCalendarRow(log: log, isEmpty: false, selectedProject: .constant(log))
                    }
                }
                
                // Tasks for this day
                if !tasks.isEmpty {
                    if !logs.isEmpty {
                        Divider()
                            .padding(.top, 4)
                    }
                    
                    Text("Tasks for this day")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                    
                    ForEach(tasks) { task in
                        TaskCalendarRow(task: task)
                    }
                }
            }
        }
    }

    private func backGroundColor() -> Color {
        colorScheme == .light ? Color(red: 242/255, green: 242/255, blue: 247/255) : .black
    }

    private func backGroundView() -> some View {
        ListBackground().ignoresSafeArea()
    }
    
    // MARK: - Task Row
    
    private struct TaskCalendarRow: View {
        let task: TaskFB
        
        var body: some View {
            NavigationLink {
                TaskDetailView(taskId: task.id)
            } label: {
                HStack(spacing: 12) {
                    // Leading status icon in a subtle capsule
                    ZStack {
                        Capsule(style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                        Image(systemName: statusIcon)
                            .font(.subheadline)
                    }
                    .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title.isEmpty ? "Untitled task" : task.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        
                        if !task.description.isEmpty {
                            Text(task.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        
                        // Small status label
                        Text(statusText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
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
    }
}

#Preview {
    CalendarLogsView()
        .environmentObject(LogsViewModel())
}
