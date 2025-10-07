//
//  CalendarHeader.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 7/30/25.
//

import SwiftUI

struct CalendarHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    /// Inputs from parent
    @Binding var currentDate: Date
    @Binding var currentWeek: [Date.Day]
    @Binding var selectedDate: Date?

    /// Shared pager index with parent (0 = prev, 1 = current, 2 = next)
    @Binding var pageIndex: Int

    /// Matched-geometry for the selected-day pill
    @Namespace private var namespace

    var body: some View {
        HeaderView()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
    }

    // MARK: - Header Layout

    @ViewBuilder
    private func HeaderView() -> some View {
        VStack(alignment: .leading, spacing: 5) {
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
    }

    // MARK: - Pager (Week strip)

    @ViewBuilder
    private var weeksDatesView: some View {
        GeometryReader { proxy in
            TabView(selection: $pageIndex) {
                ForEach(0..<3, id: \.self) { idx in
                    let offset = idx - 1 // -1, 0, +1
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

                        divider(offset: 1)
                    }
                    .frame(width: proxy.size.width)
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.interactiveSpring(), value: pageIndex)
        }
        .frame(height: 80)
        .onChange(of: currentDate) { _, newValue in
            currentWeek = Date.currentWeek(from: newValue)
            selectedDate = currentDate
        }
    }

    // MARK: - Toolbar

    private var toolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                previousWeekButton
            }
            ToolbarItem(placement: .principal) {
                weekTitle
            }
            ToolbarItem(placement: .topBarTrailing) {
                nextWeekButton
            }
        }
    }

    private var previousWeekButton: some View {
        Button { pageIndex = 0 } label: {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundStyle(K.Colors.accent)
        }
    }

    private var nextWeekButton: some View {
        Button { pageIndex = 2 } label: {
            Image(systemName: "chevron.right")
                .font(.title2)
                .foregroundStyle(K.Colors.accent)
        }
    }

    // MARK: - Title

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
                // parent will keep pageIndex centered
            } label: {
                if target == current {
                    Text("This Week").font(.body.bold())
                } else if target == current + 1 {
                    Text("Next Week").font(.body.bold())
                } else if target == current - 1 {
                    Text("Previous Week").font(.body.bold())
                } else {
                    let firstDate = currentWeek.first?.date.string("M/d") ?? ""
                    let lastDate = currentWeek.last?.date.string("M/d") ?? ""
                    Text("\(firstDate) - \(lastDate)").font(.body.bold())
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Misc

    private func divider(offset: CGFloat = 0) -> some View {
        Divider()
            .frame(height: 35)
            .offset(x: offset)
    }

    private func usualColor() -> Color {
        colorScheme == .light ? .black : .white
    }

    private func selctedColor() -> Color {
        colorScheme == .dark ? .black : .white
    }
}
