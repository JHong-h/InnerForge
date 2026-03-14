import Foundation
import SwiftData

// MARK: - Enums

public enum AIProvider: String, Codable, CaseIterable, Sendable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case custom = "custom"

    public var displayName: String {
        switch self {
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .custom: "自定义 (OpenAI 兼容)"
        }
    }
}

public enum ObservationStatus: String, Codable, Sendable {
    case active
    case paused
    case completed
    case archived
}

public enum Mood: Int, Codable, CaseIterable, Sendable {
    case veryLow = 1
    case low = 2
    case neutral = 3
    case good = 4
    case great = 5

    public var emoji: String {
        switch self {
        case .veryLow: "😞"
        case .low: "😔"
        case .neutral: "😐"
        case .good: "🙂"
        case .great: "😊"
        }
    }

    public var label: String {
        switch self {
        case .veryLow: "很低落"
        case .low: "低落"
        case .neutral: "平静"
        case .good: "不错"
        case .great: "很好"
        }
    }
}

public enum ReportType: String, Codable, Sendable {
    case dailyInsight = "daily_insight"
    case periodSummary = "period_summary"
    case restructurePlan = "restructure_plan"

    public var displayName: String {
        switch self {
        case .dailyInsight: "每日洞察"
        case .periodSummary: "观察期总结"
        case .restructurePlan: "重构方案"
        }
    }
}

public enum SkillExecutionStatus: String, Codable, Sendable {
    case pending
    case running
    case completed
    case failed
}

// MARK: - Skill Permission

public enum SkillPermission: String, Codable, Sendable, CaseIterable {
    case readEntries
    case readReports
    case callAI
    case writeReports

    public var displayName: String {
        switch self {
        case .readEntries: "读取日记"
        case .readReports: "读取报告"
        case .callAI: "调用 AI"
        case .writeReports: "写入报告"
        }
    }
}
