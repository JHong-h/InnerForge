import SwiftUI
import SwiftData
import AppKit
import IFCore
import IFStorage
import IFObservation

@MainActor
@Observable
final class EntryViewModel {
    var entries: [DailyEntry] = []
    var selectedEntry: DailyEntry?
    var editContent = ""
    var editMood: Mood?
    var isDirty = false

    private var service: EntryService?

    func load(context: ModelContext, period: ObservationPeriod) {
        self.service = EntryService(modelContext: context)
        entries = period.entries.sorted { $0.date > $1.date }
    }

    func selectEntry(_ entry: DailyEntry) {
        saveIfDirty()
        selectedEntry = entry
        editContent = entry.content
        editMood = entry.mood
        isDirty = false
    }

    func createEntry(for period: ObservationPeriod) {
        guard let service else { return }
        let entry = service.createEntry(for: period)
        entries.insert(entry, at: 0)
        selectEntry(entry)
    }

    func createTodayEntry(for period: ObservationPeriod) {
        guard let service else { return }
        if let existing = service.todayEntry(for: period) {
            selectEntry(existing)
        } else {
            createEntry(for: period)
        }
    }

    func saveIfDirty() {
        guard isDirty, let entry = selectedEntry, let service else { return }
        service.updateEntry(entry, content: editContent, mood: editMood)
        isDirty = false
    }

    func deleteEntry(_ entry: DailyEntry) {
        service?.deleteEntry(entry)
        entries.removeAll { $0.id == entry.id }
        if selectedEntry?.id == entry.id {
            selectedEntry = nil
            editContent = ""
            editMood = nil
        }
    }

    func addImage(_ image: NSImage) {
        guard let entry = selectedEntry, let service else { return }
        _ = try? service.addAttachment(to: entry, image: image)
    }

    func contentChanged() {
        isDirty = true
    }
}
