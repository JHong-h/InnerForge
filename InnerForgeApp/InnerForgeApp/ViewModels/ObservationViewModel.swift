import SwiftUI
import SwiftData
import IFCore
import IFObservation

@MainActor
@Observable
final class ObservationViewModel {
    var periods: [ObservationPeriod] = []
    var selectedPeriod: ObservationPeriod?
    var isShowingNewPeriod = false

    // New period fields
    var newTitle = ""
    var newIntention = ""
    var newDuration = 7

    private var service: ObservationService?

    func load(context: ModelContext) {
        self.service = ObservationService(modelContext: context)
        let descriptor = FetchDescriptor<ObservationPeriod>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        periods = (try? context.fetch(descriptor)) ?? []
    }

    func createPeriod() {
        guard let service, !newTitle.isEmpty else { return }
        let period = service.createPeriod(title: newTitle, intention: newIntention, durationDays: max(7, newDuration))
        periods.insert(period, at: 0)
        selectedPeriod = period
        isShowingNewPeriod = false
        resetNewFields()
    }

    func endPeriod(_ period: ObservationPeriod) {
        service?.endPeriod(period)
    }

    func deletePeriod(_ period: ObservationPeriod) {
        service?.deletePeriod(period)
        periods.removeAll { $0.id == period.id }
        if selectedPeriod?.id == period.id { selectedPeriod = nil }
    }

    private func resetNewFields() {
        newTitle = ""
        newIntention = ""
        newDuration = 7
    }
}
