import SwiftUI
import SwiftData
import IFCore
import IFStorage
import IFAI

@MainActor
@Observable
final class AISettingsViewModel {
    var configs: [AIModelConfig] = []
    var editingConfig: AIModelConfig?
    var isShowingEditor = false
    var isTesting = false
    var testResult: String?

    // Editor fields
    var name = ""
    var provider: AIProvider = .openAI
    var endpoint = ""
    var modelId = ""
    var apiKey = ""
    var isDefault = false

    private var modelContext: ModelContext?

    func load(context: ModelContext) {
        self.modelContext = context
        let descriptor = FetchDescriptor<AIModelConfig>(sortBy: [SortDescriptor(\.createdAt)])
        configs = (try? context.fetch(descriptor)) ?? []
    }

    func startNew() {
        editingConfig = nil
        name = ""
        provider = .openAI
        endpoint = ""
        modelId = ""
        apiKey = ""
        isDefault = configs.isEmpty
        isShowingEditor = true
    }

    func startEdit(_ config: AIModelConfig) {
        editingConfig = config
        name = config.name
        provider = config.provider
        endpoint = config.endpoint
        modelId = config.modelId
        apiKey = KeychainHelper.load(key: config.apiKeyRef) ?? ""
        isDefault = config.isDefault
        isShowingEditor = true
    }

    func save() {
        guard let context = modelContext else { return }

        if isDefault {
            for c in configs { c.isDefault = false }
        }

        if let existing = editingConfig {
            existing.name = name
            existing.provider = provider
            existing.endpoint = endpoint
            existing.modelId = modelId
            existing.isDefault = isDefault
            if !apiKey.isEmpty {
                try? KeychainHelper.save(key: existing.apiKeyRef, value: apiKey)
            }
        } else {
            let config = AIModelConfig(name: name, provider: provider, endpoint: endpoint, modelId: modelId, isDefault: isDefault)
            config.apiKeyRef = "innerforge.apikey.\(config.id.uuidString)"
            if !apiKey.isEmpty {
                try? KeychainHelper.save(key: config.apiKeyRef, value: apiKey)
            }
            context.insert(config)
        }

        try? context.save()
        load(context: context)
        isShowingEditor = false
    }

    func delete(_ config: AIModelConfig) {
        guard let context = modelContext else { return }
        KeychainHelper.delete(key: config.apiKeyRef)
        context.delete(config)
        try? context.save()
        load(context: context)
    }

    func testConnection(_ config: AIModelConfig) {
        isTesting = true
        testResult = nil
        let service = AIServiceFactory.create(for: config)
        Task {
            do {
                let ok = try await service.testConnection()
                testResult = ok ? "连接成功" : "连接失败"
            } catch {
                testResult = "错误: \(error.localizedDescription)"
            }
            isTesting = false
        }
    }

    var defaultConfig: AIModelConfig? {
        configs.first(where: { $0.isDefault }) ?? configs.first
    }
}
