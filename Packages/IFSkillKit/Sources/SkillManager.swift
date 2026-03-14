import Foundation
import IFCore

// MARK: - Skill Manager

@MainActor
@Observable
public final class SkillManager {
    public private(set) var registeredSkills: [String: any SkillProtocol] = [:]
    public private(set) var isExecuting = false

    public init() {}

    public func register(_ skill: any SkillProtocol) {
        registeredSkills[skill.skillId] = skill
    }

    public func skill(for id: String) -> (any SkillProtocol)? {
        registeredSkills[id]
    }

    public var allSkills: [any SkillProtocol] {
        Array(registeredSkills.values)
    }

    public func execute(skillId: String, context: SkillContext) async throws -> SkillOutput {
        guard let skill = registeredSkills[skillId] else {
            throw SkillError.executionFailed("Skill not found: \(skillId)")
        }
        isExecuting = true
        defer { isExecuting = false }
        return try await skill.execute(context: context)
    }
}
