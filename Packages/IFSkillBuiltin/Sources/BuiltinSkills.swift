// Re-export for convenience
@_exported import IFSkillKit

public enum BuiltinSkills {
    public static var all: [any SkillProtocol] {
        [
            DailyInsightSkill(),
            PeriodSummarySkill(),
            RestructurePlanSkill(),
        ]
    }
}
