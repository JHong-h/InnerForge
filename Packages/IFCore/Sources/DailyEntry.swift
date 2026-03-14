import Foundation
import SwiftData

// MARK: - DailyEntry

@Model
public final class DailyEntry {
    public var id: UUID
    public var date: Date
    public var content: String
    public var mood: Mood?
    public var createdAt: Date
    public var updatedAt: Date

    public var period: ObservationPeriod?

    @Relationship(deleteRule: .cascade, inverse: \Attachment.entry)
    public var attachments: [Attachment]

    @Relationship(deleteRule: .cascade, inverse: \AnalysisReport.entry)
    public var reports: [AnalysisReport]

    public init(
        date: Date = Date(),
        content: String = "",
        mood: Mood? = nil,
        period: ObservationPeriod? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.content = content
        self.mood = mood
        self.createdAt = Date()
        self.updatedAt = Date()
        self.period = period
        self.attachments = []
        self.reports = []
    }

    public var dateString: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    public var wordCount: Int {
        content.count
    }
}
