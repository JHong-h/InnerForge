import Foundation
import SwiftData

// MARK: - SkillRecord

@Model
public final class SkillRecord {
    public var id: UUID
    public var skillId: String
    public var skillName: String
    public var input: String
    public var output: String?
    public var status: SkillExecutionStatus
    public var errorMessage: String?
    public var startedAt: Date
    public var completedAt: Date?
    public var tokenUsage: Int?

    public init(
        skillId: String,
        skillName: String,
        input: String
    ) {
        self.id = UUID()
        self.skillId = skillId
        self.skillName = skillName
        self.input = input
        self.status = .pending
        self.startedAt = Date()
    }
}
