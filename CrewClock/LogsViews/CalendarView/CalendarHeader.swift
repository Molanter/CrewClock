//
//  CalendarHeader.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/30/25.
//

import SwiftUI

struct CalendarHeader: View {
    @Environment(\.colorScheme) var colorScheme
    
    /// View Properties
    @Binding var currentDate: Date
    @Binding var currentWeek: [Date.Day]
    @Binding var selectedDate: Date?
    /// For Matched Geometry Effect
    @Namespace private var namespace
    
    var body: some View {
        HeaderView()
            .navigationBarTitleDisplayMode(.inline)
            .background {
                TransparentBlurView(removeAllFilters: false)
                    .blur(radius: 9, opaque: true)
                    .background(.white.opacity(0.1))
            }
            .frame(height: 100)
    }
    
    func HeaderView() -> some View {
        VStack(alignment: .leading, spacing: 5) {
            /// Week View
            weeksDatesView
            
            HStack {
                Text(selectedDate?.string("MMM") ?? "")
                
                Spacer()
                
                Text(selectedDate?.string("YYYY") ?? "")
            }
            .font(.caption2)
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
        .toolbar {
            toolbar
        }
    }
    
    private var toolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                previousWeekButton
            }
            ToolbarItem(placement: .principal){
                weekTitle
            }
            ToolbarItem(placement: .topBarTrailing) {
                nextWeekButton
            }
        }
    }
    
    @ViewBuilder

    private var weeksDatesView: some View {
        GeometryReader { proxy in
            TabView(selection: $currentDate) {
                ForEach([-1, 0, 1], id: \.self) { offset in
                    let weekBaseDate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: currentDate) ?? currentDate
                    let weekDays = Date.currentWeek(from: weekBaseDate)
                    
                    HStack(spacing: 0) {
                        ForEach(weekDays) { day in
                            let date = day.date
                            let isSameDate = date.isSame(selectedDate)
                            
                            VStack(spacing: 6) {
                                Text(date.string("EEE"))
                                    .font(.caption)
                                
                                Text(date.string("dd"))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(isSameDate ? selctedColor() : usualColor())
                                    .frame(width: 38, height: 38)
                                    .background {
                                        if isSameDate {
                                            Circle()
                                                .fill(K.Colors.accent)
                                                .matchedGeometryEffect(id: "ACTIVEDATE", in: namespace)
                                        }
                                    }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(.rect)
                            .onTapGesture {
                                withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                                    selectedDate = date
                                }
                            }
                        }
                    }
                    .frame(width: proxy.size.width)
                    .tag(weekBaseDate)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .frame(height: 80)
        .onChange(of: currentDate) { old, newValue in
            currentWeek = Date.currentWeek(from: newValue)
            selectedDate = currentDate
        }
    }
    
    private var weekTitle: some View {
        Group {
            let calendar = Calendar.current
            let now = Date()
            let current = calendar.component(.weekOfYear, from: now)
            let target = calendar.component(.weekOfYear, from: currentWeek.first?.date ?? now)
            
            Button {
                let today = Date()
                        currentDate = today
                        currentWeek = Date.currentWeek(from: today)
                        selectedDate = today
            }label: {
                if target == current {
                    Text("This Week")
                        .font(.body.bold())
                } else if target == current + 1 {
                    Text("Next Week")
                        .font(.body.bold())
                } else if target == current - 1 {
                    Text("Previous Week")
                        .font(.body.bold())
                } else {
                    let firstDate = currentWeek.first?.date.string("M/d") ?? ""
                    let lastDate = currentWeek.last?.date.string("M/d") ?? ""
                    Text("\(firstDate) - \(lastDate)")
                        .font(.body.bold())
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private var previousWeekButton: some View {
        Button(action: {
            currentDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate
            currentWeek = Date.currentWeek(from: currentDate)
            selectedDate = currentWeek.first?.date
        }) {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundStyle(K.Colors.accent)
            
        }
    }
    
    private var nextWeekButton: some View {
        Button(action: {
            currentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            currentWeek = Date.currentWeek(from: currentDate)
            selectedDate = currentWeek.first?.date
        }) {
            Image(systemName: "chevron.right")
                .font(.title2)
                .foregroundStyle(K.Colors.accent)
        }
    }
    
    private func usualColor() -> Color {
        return colorScheme == .light ? Color.black : Color.white
    }
    
    private func selctedColor() -> Color {
        return colorScheme == .dark ? Color.black : Color.white

    }
}

#Preview {
    CalendarLogsView()
        .environmentObject(LogsViewModel())}
