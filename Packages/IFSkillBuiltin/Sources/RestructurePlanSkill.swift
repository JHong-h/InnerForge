import Foundation
import IFCore
import IFSkillKit

// MARK: - Restructure Plan Skill

public struct RestructurePlanSkill: SkillProtocol {
    public let skillId = "builtin.restructure_plan"
    public let displayName = "重构方案"
    public let description = "基于剖析报告生成可执行的重构建议"
    public let version = "1.0.0"
    public let requiredPermissions: Set<SkillPermission> = [.readReports, .callAI, .writeReports]

    public init() {}

    public func execute(context: SkillContext) async throws -> SkillOutput {
        try context.requirePermission(.readReports)

        guard let period = context.period else {
            throw SkillError.executionFailed("未指定观察期")
        }

        let summaryReport = context.reports
            .filter { $0.type == .periodSummary }
            .sorted { $0.createdAt > $1.createdAt }
            .first

        guard let summary = summaryReport else {
            throw SkillError.executionFailed("请先生成观察期总结报告")
        }

        let template = PromptLoader.load("restructure_plan")
        let prompt = PromptLoader.render(template, variables: [
            "title": period.title,
            "intention": period.intention,
            "summaryReport": summary.content,
        ])

        let messages = [
            AIMessage(role: .system, content: "你是 InnerForge 的 AI 分析助手。"),
            AIMessage(role: .user, content: prompt),
        ]

        let result = try await context.callAI(messages: messages)

        return SkillOutput(
            title: "重构方案 — \(period.title)",
            content: result,
            reportType: .restructurePlan
        )
    }
}
