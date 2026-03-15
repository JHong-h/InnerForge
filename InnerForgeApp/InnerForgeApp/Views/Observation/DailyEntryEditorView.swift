import SwiftUI
import AppKit
import UniformTypeIdentifiers
import IFCore
import IFStorage

struct DailyEntryEditorView: View {
    let entry: DailyEntry
    @Binding var content: String
    @Binding var mood: Mood?
    var onChanged: () -> Void
    var onSave: () -> Void
    var onAnalyze: () -> Void
    var onImageAdded: ((NSImage) -> Void)?
    var isAnalyzing: Bool

    @State private var showPreview = false
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(entry.date, style: .date)
                    .font(.headline)

                Spacer()

                moodPicker

                Toggle(isOn: $showPreview) {
                    Image(systemName: "eye")
                }
                .toggleStyle(.button)
                .help("预览 Markdown")

                Button("保存") { onSave() }
                    .keyboardShortcut("s", modifiers: .command)

                Button {
                    pickImage()
                } label: {
                    Image(systemName: "photo.badge.plus")
                }
                .help("添加图片 (也可拖拽或 ⌘V 粘贴)")

                Button {
                    onSave()
                    onAnalyze()
                } label: {
                    if isAnalyzing {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("AI 洞察", systemImage: "sparkles")
                    }
                }
                .disabled(content.isEmpty || isAnalyzing)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Editor area
            if showPreview {
                HSplitView {
                    editor
                    Divider()
                    ScrollView {
                        Text(LocalizedStringKey(content))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            } else {
                editor
            }

            // Attachments
            if !entry.attachments.isEmpty {
                Divider()
                attachmentBar
            }
        }
        .onDrop(of: [.image], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 3)
                    .background(Color.accentColor.opacity(0.05))
                    .allowsHitTesting(false)
            }
        }
        .onCommand(#selector(NSResponder.paste(_:))) {
            pasteImage()
        }
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.begin { response in
            guard response == .OK else { return }
            for url in panel.urls {
                if let image = NSImage(contentsOf: url) {
                    onImageAdded?(image)
                }
            }
        }
    }

    private func pasteImage() {
        let pb = NSPasteboard.general
        guard let items = pb.pasteboardItems else { return }
        for item in items {
            for type in [UTType.png, UTType.jpeg, UTType.tiff] {
                if let data = item.data(forType: .init(type.identifier)),
                   let image = NSImage(data: data) {
                    onImageAdded?(image)
                    return
                }
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSImage.self) {
                provider.loadObject(ofClass: NSImage.self) { object, _ in
                    if let image = object as? NSImage {
                        DispatchQueue.main.async {
                            onImageAdded?(image)
                        }
                    }
                }
                return true
            }
        }
        return false
    }

    private var editor: some View {
        TextEditor(text: $content)
            .font(.body.monospaced())
            .scrollContentBackground(.hidden)
            .padding(8)
            .onChange(of: content) { _, _ in onChanged() }
    }

    private var moodPicker: some View {
        HStack(spacing: 4) {
            ForEach(Mood.allCases, id: \.self) { m in
                Button {
                    mood = (mood == m) ? nil : m
                    onChanged()
                } label: {
                    Text(m.emoji)
                        .font(.title3)
                        .opacity(mood == m ? 1.0 : 0.3)
                }
                .buttonStyle(.plain)
                .help(m.label)
            }
        }
    }

    private var attachmentBar: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(entry.attachments) { att in
                    let url = AttachmentManager.fullURL(for: att.thumbnailPath ?? att.relativePath)
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(8)
        }
        .frame(height: 76)
    }
}
