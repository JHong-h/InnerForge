import Foundation
import IFCore

// MARK: - Anthropic Service

public final class AnthropicService: AIServiceProtocol, @unchecked Sendable {
    private let endpoint: String
    private let apiKey: String
    private let model: String
    private let session: URLSession

    public init(endpoint: String, apiKey: String, model: String) {
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.model = model
        self.session = URLSession.shared
    }

    public func sendMessages(_ messages: [AIMessage], model: String) async throws -> String {
        let url = URL(string: "\(endpoint)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 120

        let systemMsg = messages.first(where: { $0.role == .system })?.content
        let chatMessages = messages.filter { $0.role != .system }.map {
            ["role": $0.role.rawValue, "content": $0.content]
        }

        var body: [String: Any] = [
            "model": model.isEmpty ? self.model : model,
            "messages": chatMessages,
            "max_tokens": 4096,
        ]
        if let sys = systemMsg { body["system"] = sys }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.requestFailed(msg)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String
        else {
            throw AIError.invalidResponse
        }
        return text
    }

    public func streamMessages(_ messages: [AIMessage], model: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = URL(string: "\(endpoint)/messages")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(self.apiKey, forHTTPHeaderField: "x-api-key")
                    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    request.timeoutInterval = 120

                    let systemMsg = messages.first(where: { $0.role == .system })?.content
                    let chatMessages = messages.filter { $0.role != .system }.map {
                        ["role": $0.role.rawValue, "content": $0.content]
                    }

                    var body: [String: Any] = [
                        "model": model.isEmpty ? self.model : model,
                        "messages": chatMessages,
                        "max_tokens": 4096,
                        "stream": true,
                    ]
                    if let sys = systemMsg { body["system"] = sys }

                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await self.session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                        throw AIError.requestFailed("HTTP error")
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if let data = payload.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let type = json["type"] as? String {
                            if type == "content_block_delta",
                               let delta = json["delta"] as? [String: Any],
                               let text = delta["text"] as? String {
                                continuation.yield(AIStreamChunk(text: text))
                            } else if type == "message_stop" {
                                continuation.yield(AIStreamChunk(text: "", isFinished: true))
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    public func testConnection() async throws -> Bool {
        let messages = [AIMessage(role: .user, content: "Hi")]
        let _ = try await sendMessages(messages, model: self.model)
        return true
    }
}
