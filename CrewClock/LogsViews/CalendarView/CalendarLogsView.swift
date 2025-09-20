//
//  CalendarLogsView.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/30/25.
//

import SwiftUI

struct CalendarLogsView: View {
    @EnvironmentObject private var logsViewModel: LogsViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentDate = Date()
    @State private var currentWeek: [Date.Day] = Date.currentWeek(from: Date())
    @State private var selectedDate: Date?
    @Namespace private var namespace
    
    
    var body: some View {
        NavigationStack {
            page
                .background(backGroundView())
        }
    }
    
    private var page: some View {
        ZStack(alignment: .top) {
            CalendarHeader(currentDate: $currentDate, currentWeek: $currentWeek, selectedDate: $selectedDate)
            calendar
                .overlay { OutsideGlassOverlay(radius: K.UI.cornerRadius) }
                .offset(y: 104)
        }
        .onAppear {
            if selectedDate == nil {
                selectedDate = currentWeek.first(where: { $0.date.isSame(.now) })?.date
            }
        }    }
    
    private var calendar: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            ScrollView(.vertical) {
                LazyVStack(spacing: 15, pinnedViews: [.sectionHeaders]) {
                    ForEach(currentWeek) { day in
                        let date = day.date
                        let isLast = currentWeek.last?.id == day.id
                        
                        Section {
                            VStack(alignment: .leading, spacing: 15) {
                                tasks(for: date)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.leading, 70)
                            .padding(.top, -70)
                            .padding(.bottom, 10)
                            .frame(minHeight: isLast ? size.height - 110 : nil, alignment: .top)
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
                currentWeek.first(where: { $0.date.isSame(selectedDate) })?.id
            }, set: { newValue in
                selectedDate = currentWeek.first(where: { $0.id == newValue })?.date
            }), anchor: .top)
            .safeAreaPadding(.bottom, 70)
            .padding(.bottom, -70)
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
    
    @ViewBuilder
    private func tasks(for date: Date) -> some View {
        return Group {
            let filteredLogs: [LogFB] = logsViewModel.logs.filter { log in
                Calendar.current.isDate(log.date, inSameDayAs: date)
            }
            if filteredLogs.isEmpty {
                let dummyLog = LogFB(
                    data: [
                        "spreadsheetId": "",
                        "row": 0,
                        "projectName": "",
                        "comment": "",
                        "date": Date(),
                        "timeStarted": Date(),
                        "timeFinished": Date(),
                        "crewUID": [],
                        "expenses": 0.0
                    ],
                    documentId: "dummy"
                )
                TaskRow(log: dummyLog, isEmpty: true, selectedProject: .constant(dummyLog))
            } else {
                ForEach(filteredLogs) { log in
                    TaskRow(log: log, isEmpty: false, selectedProject: .constant(log))
                }
            }
        }
    }
    
    private func backGroundColor() -> Color {
        return colorScheme == .light ? Color(red: 242, green: 242, blue: 247) : .black
    }
    
    private func backGroundView() -> some View {
        return ListBackground().ignoresSafeArea()
    }
}

#Preview {
    CalendarLogsView()
        .environmentObject(LogsViewModel())
}

