import SwiftUI
import IFCore

struct CalendarView: View {
    let entries: [DailyEntry]
    let month: Date
    var onSelectDate: (Date) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 8) {
            Text(month, format: .dateTime.year().month())
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                ForEach(daysInMonth(), id: \.self) { date in
                    if let date {
                        let hasEntry = entries.contains { calendar.isDate($0.date, inSameDayAs: date) }
                        let entry = entries.first { calendar.isDate($0.date, inSameDayAs: date) }
                        Button {
                            onSelectDate(date)
                        } label: {
                            VStack(spacing: 1) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.caption)
                                if let mood = entry?.mood {
                                    Text(mood.emoji).font(.system(size: 8))
                                } else if hasEntry {
                                    Circle().fill(.blue).frame(width: 4, height: 4)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 28)
                            .background(calendar.isDateInToday(date) ? Color.accentColor.opacity(0.1) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("")
                            .frame(maxWidth: .infinity, minHeight: 28)
                    }
                }
            }
        }
        .padding()
    }

    private func daysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: month)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let weekday = calendar.component(.weekday, from: firstDay) - 1

        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
}
