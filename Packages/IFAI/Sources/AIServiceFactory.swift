import Foundation
import IFCore
import IFStorage

// MARK: - AI Service Factory

public enum AIServiceFactory {
    public static func create(for config: AIModelConfig) -> AIServiceProtocol {
        let apiKey = KeychainHelper.load(key: config.apiKeyRef) ?? ""
        switch config.provider {
        case .openAI, .custom:
            return OpenAIService(endpoint: config.effectiveEndpoint, apiKey: apiKey, model: config.modelId)
        case .anthropic:
            return AnthropicService(endpoint: config.effectiveEndpoint, apiKey: apiKey, model: config.modelId)
        }
    }
}
