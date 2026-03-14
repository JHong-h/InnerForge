import Foundation
import IFCore
import IFSkillKit

// MARK: - Period Summary Skill

public struct PeriodSummarySkill: SkillProtocol {
    public let skillId = "builtin.period_summary"
    public let displayName = "观察期总结"
    public let description = "汇总观察期所有记录，生成剖析报告"
    public let version = "1.0.0"
    public let requiredPermissions: Set<SkillPermission> = [.readEntries, .callAI, .writeReports]

    public init() {}

    public func execute(context: SkillContext) async throws -> SkillOutput {
        try context.requirePermission(.readEntries)

        guard let period = context.period else {
            throw SkillError.executionFailed("未指定观察期")
        }

        let entriesText = context.entries
            .sorted { $0.date < $1.date }
            .map { entry in
                let mood = entry.mood?.label ?? "未记录"
                return "#### \(entry.date.formatted(date: .long, time: .omitted))（心情：\(mood)）\n\(entry.content)"
            }
            .joined(separator: "\n\n---\n\n")

        let template = PromptLoader.load("period_summary")
        let prompt = PromptLoader.render(template, variables: [
            "title": period.title,
            "intention": period.intention,
            "startDate": period.startDate.formatted(date: .long, time: .omitted),
            "endDate": period.plannedEndDate.formatted(date: .long, time: .omitted),
            "totalDays": "\(Calendar.current.dateComponents([.day], from: period.startDate, to: period.plannedEndDate).day ?? 0)",
            "entryCount": "\(context.entries.count)",
            "entries": entriesText,
        ])

        let messages = [
            AIMessage(role: .system, content: "你是 InnerForge 的 AI 分析助手。"),
            AIMessage(role: .user, content: prompt),
        ]

        let result = try await context.callAI(messages: messages)

        return SkillOutput(
            title: "观察期总结 — \(period.title)",
            content: result,
            reportType: .periodSummary
        )
    }
}
