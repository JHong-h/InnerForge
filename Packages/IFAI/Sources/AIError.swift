import Foundation

// MARK: - AI Errors

public enum AIError: LocalizedError {
    case requestFailed(String)
    case invalidResponse
    case noAPIKey
    case rateLimited

    public var errorDescription: String? {
        switch self {
        case .requestFailed(let msg): return "AI 请求失败: \(msg)"
        case .invalidResponse: return "AI 返回了无效的响应"
        case .noAPIKey: return "未配置 API Key"
        case .rateLimited: return "请求频率超限，请稍后重试"
        }
    }
}
