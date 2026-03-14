import Foundation
import IFCore
import IFSkillKit

// MARK: - Prompt Loader

enum PromptLoader {
    static func load(_ name: String) -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: "md", subdirectory: "Prompts"),
              let content = try? String(contentsOf: url, encoding: .utf8)
        else {
            return ""
        }
        return content
    }

    static func render(_ template: String, variables: [String: String]) -> String {
        var result = template
        for (key, value) in variables {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return result
    }
}
