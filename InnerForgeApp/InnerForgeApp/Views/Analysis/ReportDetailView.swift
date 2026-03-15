import SwiftUI
import AppKit
import UniformTypeIdentifiers
import IFCore

struct ReportDetailView: View {
    let report: AnalysisReport
    @State private var isExporting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        typeBadge
                        Spacer()
                        Text(report.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(report.title)
                        .font(.title2.bold())

                    if let period = report.period {
                        Text("观察期: \(period.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let entry = report.entry {
                        Text("日记: \(entry.dateString)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Content
                Text(LocalizedStringKey(report.content))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
        }
        .navigationTitle(report.title)
        .toolbar {
            Button("导出", systemImage: "square.and.arrow.up") {
                exportReport()
            }
        }
    }

    @ViewBuilder
    private var typeBadge: some View {
        let (text, color): (String, Color) = {
            switch report.type {
            case .dailyInsight: return ("每日洞察", .green)
            case .periodSummary: return ("观察期总结", .blue)
            case .restructurePlan: return ("重构方案", .purple)
            }
        }()
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func exportReport() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(report.title).md"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let text = "# \(report.title)\n\n> \(report.createdAt.formatted())\n\n\(report.content)"
                try? text.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}
