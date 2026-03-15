import Foundation
import IFCore

// MARK: - Skill Protocol

public protocol SkillProtocol: Sendable {
    var skillId: String { get }
    var displayName: String { get }
    var description: String { get }
    var version: String { get }
    var requiredPermissions: Set<SkillPermission> { get }

    func execute(context: SkillContext) async throws -> SkillOutput
}

// MARK: - Skill Output

public struct SkillOutput: Sendable {
    public let title: String
    public let content: String
    public let reportType: ReportType
    public let metadata: [String: String]

    public init(title: String, content: String, reportType: ReportType, metadata: [String: String] = [:]) {
        self.title = title
        self.content = content
        self.reportType = reportType
        self.metadata = metadata
    }
}

// MARK: - Skill Context (Sandbox)

@MainActor
public final class SkillContext: Sendable {
    private let grantedPermissions: Set<SkillPermission>
    private let aiService: AIServiceProtocol?
    private let modelId: String

    public let period: PeriodDTO?
    public let entries: [EntryDTO]
    public let reports: [ReportDTO]
    public let targetEntry: EntryDTO?

    public init(
        permissions: Set<SkillPermission>,
        aiService: AIServiceProtocol? = nil,
        modelId: String = "",
        period: PeriodDTO? = nil,
        entries: [EntryDTO] = [],
        reports: [ReportDTO] = [],
        targetEntry: EntryDTO? = nil
    ) {
        self.grantedPermissions = permissions
        self.aiService = aiService
        self.modelId = modelId
        self.period = period
        self.entries = entries
        self.reports = reports
        self.targetEntry = targetEntry
    }

    public func requirePermission(_ permission: SkillPermission) throws {
        guard grantedPermissions.contains(permission) else {
            throw SkillError.permissionDenied(permission)
        }
    }

    public func callAI(messages: [AIMessage]) async throws -> String {
        try requirePermission(.callAI)
        guard let service = aiService else { throw SkillError.noAIService }
        return try await service.sendMessages(messages, model: modelId)
    }

    public func streamAI(messages: [AIMessage]) throws -> AsyncThrowingStream<AIStreamChunk, Error> {
        try requirePermission(.callAI)
        guard let service = aiService else { throw SkillError.noAIService }
        return service.streamMessages(messages, model: modelId)
    }
}

// MARK: - Skill Error

public enum SkillError: LocalizedError {
    case permissionDenied(SkillPermission)
    case noAIService
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let p): return "Skill 缺少权限: \(p.displayName)"
        case .noAIService: return "未配置 AI 服务"
        case .executionFailed(let msg): return "Skill 执行失败: \(msg)"
        }
    }
}
