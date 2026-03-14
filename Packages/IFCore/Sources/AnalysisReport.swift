import Foundation
import SwiftData

// MARK: - AnalysisReport

@Model
public final class AnalysisReport {
    public var id: UUID
    public var type: ReportType
    public var title: String
    public var content: String
    public var skillId: String
    public var createdAt: Date

    public var period: ObservationPeriod?
    public var entry: DailyEntry?

    public init(
        type: ReportType,
        title: String,
        content: String,
        skillId: String,
        period: ObservationPeriod? = nil,
        entry: DailyEntry? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.content = content
        self.skillId = skillId
        self.createdAt = Date()
        self.period = period
        self.entry = entry
    }
}
