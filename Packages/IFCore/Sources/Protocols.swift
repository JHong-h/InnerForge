import Foundation

// MARK: - AI Service Protocol

public struct AIMessage: Sendable {
    public let role: AIRole
    public let content: String

    public init(role: AIRole, content: String) {
        self.role = role
        self.content = content
    }
}

public enum AIRole: String, Sendable {
    case system
    case user
    case assistant
}

public struct AIStreamChunk: Sendable {
    public let text: String
    public let isFinished: Bool

    public init(text: String, isFinished: Bool = false) {
        self.text = text
        self.isFinished = isFinished
    }
}

public protocol AIServiceProtocol: Sendable {
    func sendMessages(_ messages: [AIMessage], model: String) async throws -> String
    func streamMessages(_ messages: [AIMessage], model: String) -> AsyncThrowingStream<AIStreamChunk, Error>
    func testConnection() async throws -> Bool
}

// MARK: - DTO types for Skill sandbox

public struct EntryDTO: Sendable {
    public let id: UUID
    public let date: Date
    public let content: String
    public let mood: Mood?

    public init(id: UUID, date: Date, content: String, mood: Mood?) {
        self.id = id
        self.date = date
        self.content = content
        self.mood = mood
    }
}

public struct ReportDTO: Sendable {
    public let id: UUID
    public let type: ReportType
    public let title: String
    public let content: String
    public let createdAt: Date

    public init(id: UUID, type: ReportType, title: String, content: String, createdAt: Date) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}

public struct PeriodDTO: Sendable {
    public let id: UUID
    public let title: String
    public let intention: String
    public let startDate: Date
    public let plannedEndDate: Date
    public let entries: [EntryDTO]

    public init(id: UUID, title: String, intention: String, startDate: Date, plannedEndDate: Date, entries: [EntryDTO]) {
        self.id = id
        self.title = title
        self.intention = intention
        self.startDate = startDate
        self.plannedEndDate = plannedEndDate
        self.entries = entries
    }
}
