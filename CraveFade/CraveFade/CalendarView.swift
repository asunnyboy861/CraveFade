import SwiftUI
import SwiftData

struct CalendarView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var stats: StatsEngine
    @State private var month: Date = .now
    @State private var selectedDay: Date?

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    monthHeader
                    weekdayRow
                    dayGrid
                    if let day = selectedDay {
                        dayDetail(day)
                    }
                }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationTitle("History")
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Previous month")
            Spacer()
            Text(month, format: .dateTime.month().year())
                .font(.headline)
            Spacer()
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                .accessibilityLabel("Next month")
        }
        .padding(.horizontal, 4)
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: month) {
            month = next
            selectedDay = nil
        }
    }

    private var weekdayRow: some View {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        return HStack {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol).font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
        }
    }

    private var daysInMonth: [Date?] {
        guard let interval = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let firstWeekday = calendar.component(.weekday, from: first) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for dayOffset in 0..<interval.count {
            days.append(calendar.date(byAdding: .day, value: dayOffset, to: first))
        }
        return days
    }

    private func dayState(_ day: Date) -> (count: Int, limit: Int, slipped: Bool) {
        let count = appState.netPuffs(on: day)
        let limit = TaperPlanEngine.dailyLimit(profile: appState.profile ?? QuitProfile(), on: day)
        let slipped = appState.allCravings().contains {
            $0.outcomeKind == .slipped && calendar.isDate($0.startedAt, inSameDayAs: day)
        }
        return (count, limit, slipped)
    }

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                if let day {
                    let state = dayState(day)
                    let isFuture = day > .now
                    Button {
                        selectedDay = day
                    } label: {
                        VStack(spacing: 2) {
                            let isSelected = selectedDay.map { calendar.isDate(day, inSameDayAs: $0) } ?? false
                            Text("\(calendar.component(.day, from: day))")
                                .font(.subheadline.weight(isSelected ? .bold : .regular))
                            if !isFuture && state.limit != .max {
                                Circle()
                                    .fill(state.slipped ? Color.amber : (state.count <= state.limit ? Color.mint : Color.orange))
                                    .frame(width: 6, height: 6)
                            } else {
                                Color.clear.frame(width: 6, height: 6)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(isFuture ? .clear : Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(isFuture)
                    .accessibilityLabel("Day \(calendar.component(.day, from: day)), \(state.count) puffs")
                } else {
                    Color.clear.frame(minHeight: 44)
                }
            }
        }
    }

    private func dayDetail(_ day: Date) -> some View {
        let events = appState.events(on: day)
        let state = dayState(day)
        return VStack(alignment: .leading, spacing: 12) {
            Text(day, format: .dateTime.month().day())
                .font(.headline)
            if state.slipped {
                Label("Slip day — your weekly rate stays intact", systemImage: "arrow.uturn.left.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.amber)
            }
            Text("Net: \(state.count) puffs · limit \(state.limit == .max ? "∞" : "\(state.limit)")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if events.isEmpty {
                Text("No puffs recorded. Fix yesterday, keep today — add a backfill below.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(events, id: \.uuid) { event in
                HStack {
                    Text(event.timestamp, format: .dateTime.hour().minute())
                        .font(.subheadline)
                    Text("· \(event.source)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        appState.correctPuff(event)
                        appState.rescheduleForecast()
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Remove this puff record with a correction")
                }
                .padding(.vertical, 2)
            }
            Button {
                appState.logPuff(source: .app, at: day)
                appState.rescheduleForecast()
            } label: {
                Label("Backfill a puff on this day", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

extension Color {
    static let amber = Color(red: 0.96, green: 0.62, blue: 0.04)
}
