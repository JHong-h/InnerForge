import Foundation
import IFCore
import IFSkillKit

// MARK: - Daily Insight Skill

public struct DailyInsightSkill: SkillProtocol {
    public let skillId = "builtin.daily_insight"
    public let displayName = "每日洞察"
    public let description = "分析单日记录，输出情绪与行为模式洞察"
    public let version = "1.0.0"
    public let requiredPermissions: Set<SkillPermission> = [.readEntries, .callAI, .writeReports]

    public init() {}

    public func execute(context: SkillContext) async throws -> SkillOutput {
        try context.requirePermission(.readEntries)

        guard let entry = context.targetEntry else {
            throw SkillError.executionFailed("未指定目标日记")
        }

        let template = PromptLoader.load("daily_insight")
        let prompt = PromptLoader.render(template, variables: [
            "date": entry.date.formatted(date: .long, time: .omitted),
            "mood": entry.mood?.label ?? "未记录",
            "content": entry.content,
        ])

        let messages = [
            AIMessage(role: .system, content: "你是 InnerForge 的 AI 分析助手。"),
            AIMessage(role: .user, content: prompt),
        ]

        let result = try await context.callAI(messages: messages)

        return SkillOutput(
            title: "每日洞察 — \(entry.date.formatted(date: .abbreviated, time: .omitted))",
            content: result,
            reportType: .dailyInsight
        )
    }
}
