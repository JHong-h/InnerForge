import Foundation
import SwiftData

// MARK: - AIModelConfig

@Model
public final class AIModelConfig {
    public var id: UUID
    public var name: String
    public var provider: AIProvider
    public var endpoint: String
    public var modelId: String
    public var apiKeyRef: String // Keychain reference key
    public var isDefault: Bool
    public var createdAt: Date

    public init(
        name: String,
        provider: AIProvider,
        endpoint: String = "",
        modelId: String,
        apiKeyRef: String = "",
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.provider = provider
        self.endpoint = endpoint
        self.modelId = modelId
        self.apiKeyRef = apiKeyRef
        self.isDefault = isDefault
        self.createdAt = Date()
    }

    public var effectiveEndpoint: String {
        if !endpoint.isEmpty { return endpoint }
        switch provider {
        case .openAI: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .custom: return endpoint
        }
    }
}
