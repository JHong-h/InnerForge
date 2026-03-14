import Foundation
import SwiftData
import IFCore
import IFAI
import IFSkillKit

// MARK: - Analysis Service

@MainActor
@Observable
public final class AnalysisService {
    private let modelContext: ModelContext
    private let skillManager: SkillManager

    public var isAnalyzing = false
    public var currentProgress: String = ""

    public init(modelContext: ModelContext, skillManager: SkillManager) {
        self.modelContext = modelContext
        self.skillManager = skillManager
    }

    public func runDailyInsight(entry: DailyEntry, aiService: AIServiceProtocol, modelId: String) async throws -> AnalysisReport {
        isAnalyzing = true
        currentProgress = "正在分析日记..."
        defer { isAnalyzing = false; currentProgress = "" }

        let entryDTO = EntryDTO(id: entry.id, date: entry.date, content: entry.content, mood: entry.mood)
        let context = SkillContext(
            permissions: [.readEntries, .callAI, .writeReports],
            aiService: aiService,
            modelId: modelId,
            targetEntry: entryDTO
        )

        let output = try await skillManager.execute(skillId: "builtin.daily_insight", context: context)
        let report = AnalysisReport(
            type: output.reportType,
            title: output.title,
            content: output.content,
            skillId: "builtin.daily_insight",
            period: entry.period,
            entry: entry
        )
        modelContext.insert(report)
        try? modelContext.save()
        return report
    }

    public func runPeriodSummary(period: ObservationPeriod, aiService: AIServiceProtocol, modelId: String) async throws -> AnalysisReport {
        isAnalyzing = true
        currentProgress = "正在生成观察期总结..."
        defer { isAnalyzing = false; currentProgress = "" }

        let entries = period.entries.map { EntryDTO(id: $0.id, date: $0.date, content: $0.content, mood: $0.mood) }
        let periodDTO = PeriodDTO(
            id: period.id, title: period.title, intention: period.intention,
            startDate: period.startDate, plannedEndDate: period.plannedEndDate, entries: entries
        )
        let context = SkillContext(
            permissions: [.readEntries, .callAI, .writeReports],
            aiService: aiService,
            modelId: modelId,
            period: periodDTO,
            entries: entries
        )

        let output = try await skillManager.execute(skillId: "builtin.period_summary", context: context)
        let report = AnalysisReport(
            type: output.reportType, title: output.title, content: output.content,
            skillId: "builtin.period_summary", period: period
        )
        modelContext.insert(report)
        try? modelContext.save()
        return report
    }

    public func runRestructurePlan(period: ObservationPeriod, aiService: AIServiceProtocol, modelId: String) async throws -> AnalysisReport {
        isAnalyzing = true
        currentProgress = "正在生成重构方案..."
        defer { isAnalyzing = false; currentProgress = "" }

        let entries = period.entries.map { EntryDTO(id: $0.id, date: $0.date, content: $0.content, mood: $0.mood) }
        let reports = period.reports.map { ReportDTO(id: $0.id, type: $0.type, title: $0.title, content: $0.content, createdAt: $0.createdAt) }
        let periodDTO = PeriodDTO(
            id: period.id, title: period.title, intention: period.intention,
            startDate: period.startDate, plannedEndDate: period.plannedEndDate, entries: entries
        )
        let context = SkillContext(
            permissions: [.readEntries, .readReports, .callAI, .writeReports],
            aiService: aiService,
            modelId: modelId,
            period: periodDTO,
            entries: entries,
            reports: reports
        )

        let output = try await skillManager.execute(skillId: "builtin.restructure_plan", context: context)
        let report = AnalysisReport(
            type: output.reportType, title: output.title, content: output.content,
            skillId: "builtin.restructure_plan", period: period
        )
        modelContext.insert(report)
        try? modelContext.save()
        return report
    }
}
