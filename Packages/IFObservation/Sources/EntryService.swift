import Foundation
import SwiftData
import AppKit
import IFCore
import IFStorage

// MARK: - Entry Service

@MainActor
@Observable
public final class EntryService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func createEntry(for period: ObservationPeriod, date: Date = Date(), content: String = "", mood: Mood? = nil) -> DailyEntry {
        let entry = DailyEntry(date: date, content: content, mood: mood, period: period)
        modelContext.insert(entry)
        try? modelContext.save()
        return entry
    }

    public func updateEntry(_ entry: DailyEntry, content: String, mood: Mood?) {
        entry.content = content
        entry.mood = mood
        entry.updatedAt = Date()
        try? modelContext.save()
    }

    public func deleteEntry(_ entry: DailyEntry) {
        for attachment in entry.attachments {
            AttachmentManager.deleteFile(relativePath: attachment.relativePath)
            if let thumb = attachment.thumbnailPath {
                AttachmentManager.deleteFile(relativePath: thumb)
            }
        }
        modelContext.delete(entry)
        try? modelContext.save()
    }

    public func addAttachment(to entry: DailyEntry, image: NSImage) throws -> Attachment {
        let (relativePath, thumbPath) = try AttachmentManager.saveImage(image, entryId: entry.id)
        let attachment = Attachment(
            relativePath: relativePath,
            thumbnailPath: thumbPath,
            fileName: relativePath,
            entry: entry
        )
        modelContext.insert(attachment)
        try? modelContext.save()
        return attachment
    }

    public func removeAttachment(_ attachment: Attachment) {
        AttachmentManager.deleteFile(relativePath: attachment.relativePath)
        if let thumb = attachment.thumbnailPath {
            AttachmentManager.deleteFile(relativePath: thumb)
        }
        modelContext.delete(attachment)
        try? modelContext.save()
    }

    public func todayEntry(for period: ObservationPeriod) -> DailyEntry? {
        let calendar = Calendar.current
        return period.entries.first { calendar.isDateInToday($0.date) }
    }
}
