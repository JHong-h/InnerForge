import Foundation
import SwiftData

// MARK: - ObservationPeriod

@Model
public final class ObservationPeriod {
    public var id: UUID
    public var title: String
    public var intention: String
    public var startDate: Date
    public var plannedEndDate: Date
    public var actualEndDate: Date?
    public var status: ObservationStatus
    public var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \DailyEntry.period)
    public var entries: [DailyEntry]

    @Relationship(deleteRule: .cascade, inverse: \AnalysisReport.period)
    public var reports: [AnalysisReport]

    public init(
        title: String,
        intention: String,
        startDate: Date = Date(),
        plannedEndDate: Date
    ) {
        self.id = UUID()
        self.title = title
        self.intention = intention
        self.startDate = startDate
        self.plannedEndDate = plannedEndDate
        self.status = .active
        self.createdAt = Date()
        self.entries = []
        self.reports = []
    }

    public var daysElapsed: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }

    public var totalPlannedDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: plannedEndDate).day ?? 0
    }

    public var isOverdue: Bool {
        status == .active && Date() > plannedEndDate
    }
}
