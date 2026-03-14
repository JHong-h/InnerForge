import Foundation
import SwiftData
import IFCore
import IFStorage

// MARK: - Observation Service

@MainActor
@Observable
public final class ObservationService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func createPeriod(title: String, intention: String, durationDays: Int) -> ObservationPeriod {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: durationDays, to: start)!
        let period = ObservationPeriod(title: title, intention: intention, startDate: start, plannedEndDate: end)
        modelContext.insert(period)
        try? modelContext.save()
        return period
    }

    public func endPeriod(_ period: ObservationPeriod) {
        period.status = .completed
        period.actualEndDate = Date()
        try? modelContext.save()
    }

    public func pausePeriod(_ period: ObservationPeriod) {
        period.status = .paused
        try? modelContext.save()
    }

    public func resumePeriod(_ period: ObservationPeriod) {
        period.status = .active
        try? modelContext.save()
    }

    public func archivePeriod(_ period: ObservationPeriod) {
        period.status = .archived
        try? modelContext.save()
    }

    public func deletePeriod(_ period: ObservationPeriod) {
        modelContext.delete(period)
        try? modelContext.save()
    }
}
