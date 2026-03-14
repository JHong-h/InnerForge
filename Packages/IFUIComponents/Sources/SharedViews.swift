import SwiftUI
import IFCore

// MARK: - Markdown Renderer

public struct MarkdownView: View {
    let content: String

    public init(_ content: String) {
        self.content = content
    }

    public var body: some View {
        ScrollView {
            Text(LocalizedStringKey(content))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

// MARK: - Loading View

public struct LoadingView: View {
    let message: String

    public init(_ message: String = "加载中...") {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View

public struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    public init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2.bold())
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Mood Badge

public struct MoodBadge: View {
    let mood: IFCore.Mood

    public init(_ mood: IFCore.Mood) {
        self.mood = mood
    }

    public var body: some View {
        Text(mood.emoji)
            .font(.title3)
            .help(mood.label)
    }
}

// MARK: - Status Badge

public struct StatusBadge: View {
    let text: String
    let color: Color

    public init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Streaming Text View

public struct StreamingTextView: View {
    let text: String
    let isStreaming: Bool

    public init(text: String, isStreaming: Bool) {
        self.text = text
        self.isStreaming = isStreaming
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(text))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isStreaming {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
    }
}
