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

    // Shared pager selection (0 = prev, 1 = current, 2 = next)
    @State private var pageIndex: Int = 1

    // How long to let the TabView page animation play before snapping back
    private let pageAnimDelay: UInt64 = 320_000_000 // ~0.32s

    var body: some View {
        NavigationStack {
            page
        }
    }

    private var page: some View {
        ZStack(alignment: .top) {

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
                .offset(y: 104)
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
        GeometryReader { proxy in
            TabView(selection: $pageIndex) {
                ForEach(0..<3, id: \.self) { idx in
                    let offset = idx - 1
                    let weekBaseDate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: currentDate) ?? currentDate
                    let weekDays = Date.currentWeek(from: weekBaseDate)

                    ScrollView(.vertical) {
                        LazyVStack(spacing: 15, pinnedViews: [.sectionHeaders]) {
                            ForEach(weekDays) { day in
                                let date = day.date
                                let isLast = weekDays.last?.id == day.id

                                Section {
                                    VStack(alignment: .leading, spacing: 15) {
                                        tasks(for: date)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.leading, 70)
                                    .padding(.top, -70)
                                    .padding(.bottom, 10)
                                    .frame(
                                        minHeight: isLast ? proxy.size.height - 110 : nil,
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
                    .contentMargins(.vertical, 20, for: .scrollIndicators)
                    .scrollPosition(id: .init(get: {
                        weekDays.first(where: { $0.date.isSame(selectedDate) })?.id
                    }, set: { newValue in
                        selectedDate = weekDays.first(where: { $0.id == newValue })?.date
                    }), anchor: .top)
                    .safeAreaPadding(.bottom, 70)
                    .padding(.bottom, -70)
                    .frame(width: proxy.size.width)
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.interactiveSpring(), value: pageIndex)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: K.UI.cornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: K.UI.cornerRadius,
                style: .continuous
            )
        )
        .ignoresSafeArea(.all, edges: .bottom)
    }

    // MARK: - Helpers

    private func shiftWeek(by delta: Int) {
        currentDate = Calendar.current.date(byAdding: .weekOfYear, value: delta, to: currentDate) ?? currentDate
        currentWeek = Date.currentWeek(from: currentDate)
        selectedDate = currentWeek.first?.date
    }

    @ViewBuilder
    private func tasks(for date: Date) -> some View {
        let filteredLogs: [LogFB] = logsViewModel.logs.filter { log in
            Calendar.current.isDate(log.date, inSameDayAs: date)
        }
        if filteredLogs.isEmpty {
            // K.Logs.dummyLog is dummy/emty log for now
            LogCalendarRow(log: K.Logs.dummyLog, isEmpty: true, selectedProject: .constant(K.Logs.dummyLog))
        } else {
            ForEach(filteredLogs) { log in
                LogCalendarRow(log: log, isEmpty: false, selectedProject: .constant(log))
            }
        }
    }

    private func backGroundColor() -> Color {
        colorScheme == .light ? Color(red: 242/255, green: 242/255, blue: 247/255) : .black
    }

    private func backGroundView() -> some View {
        ListBackground().ignoresSafeArea()
    }
}

#Preview {
    CalendarLogsView()
        .environmentObject(LogsViewModel())
}
