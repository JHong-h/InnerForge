import SwiftUI
import SwiftData
import IFCore
import IFAI
import IFSkillKit
import IFAnalysis

@MainActor
@Observable
final class AnalysisViewModel {
    var reports: [AnalysisReport] = []
    var selectedReport: AnalysisReport?
    var isAnalyzing = false
    var errorMessage: String?

    private var analysisService: AnalysisService?

    func load(context: ModelContext, skillManager: SkillManager) {
        self.analysisService = AnalysisService(modelContext: context, skillManager: skillManager)
        let descriptor = FetchDescriptor<AnalysisReport>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        reports = (try? context.fetch(descriptor)) ?? []
    }

    func runDailyInsight(entry: DailyEntry, config: AIModelConfig) {
        guard let analysisService else { return }
        isAnalyzing = true
        errorMessage = nil
        let service = AIServiceFactory.create(for: config)
        Task {
            do {
                let report = try await analysisService.runDailyInsight(entry: entry, aiService: service, modelId: config.modelId)
                reports.insert(report, at: 0)
                selectedReport = report
            } catch {
                errorMessage = error.localizedDescription
            }
            isAnalyzing = false
        }
    }

    func runPeriodSummary(period: ObservationPeriod, config: AIModelConfig) {
        guard let analysisService else { return }
        isAnalyzing = true
        errorMessage = nil
        let service = AIServiceFactory.create(for: config)
        Task {
            do {
                let report = try await analysisService.runPeriodSummary(period: period, aiService: service, modelId: config.modelId)
                reports.insert(report, at: 0)
                selectedReport = report
            } catch {
                errorMessage = error.localizedDescription
            }
            isAnalyzing = false
        }
    }

    func runRestructurePlan(period: ObservationPeriod, config: AIModelConfig) {
        guard let analysisService else { return }
        isAnalyzing = true
        errorMessage = nil
        let service = AIServiceFactory.create(for: config)
        Task {
            do {
                let report = try await analysisService.runRestructurePlan(period: period, aiService: service, modelId: config.modelId)
                reports.insert(report, at: 0)
                selectedReport = report
            } catch {
                errorMessage = error.localizedDescription
            }
            isAnalyzing = false
        }
    }
}
