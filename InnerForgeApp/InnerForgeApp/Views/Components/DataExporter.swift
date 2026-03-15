import Foundation
import SwiftData
import AppKit
import IFCore
import IFStorage

enum DataExporter {
    static func exportAll(context: ModelContext) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "选择导出目录"

        panel.begin { response in
            guard response == .OK, let baseURL = panel.url else { return }

            Task { @MainActor in
                do {
                    try exportPeriods(context: context, to: baseURL)
                    try exportReports(context: context, to: baseURL)
                    NSWorkspace.shared.open(baseURL)
                } catch {
                    let alert = NSAlert()
                    alert.messageText = "导出失败"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }

    @MainActor
    private static func exportPeriods(context: ModelContext, to baseURL: URL) throws {
        let descriptor = FetchDescriptor<ObservationPeriod>(sortBy: [SortDescriptor(\.createdAt)])
        let periods = try context.fetch(descriptor)

        for period in periods {
            let safeName = period.title.replacingOccurrences(of: "/", with: "-")
            let periodDir = baseURL.appendingPathComponent("观察期_\(safeName)", isDirectory: true)
            try FileManager.default.createDirectory(at: periodDir, withIntermediateDirectories: true)

            // Period info
            let info = """
            # \(period.title)

            - 意图: \(period.intention)
            - 状态: \(period.status.rawValue)
            - 开始: \(period.startDate.formatted(date: .long, time: .omitted))
            - 计划结束: \(period.plannedEndDate.formatted(date: .long, time: .omitted))
            - 实际结束: \(period.actualEndDate?.formatted(date: .long, time: .omitted) ?? "进行中")
            - 日记数: \(period.entries.count)
            """
            try info.write(to: periodDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)

            // Entries
            let entriesDir = periodDir.appendingPathComponent("日记", isDirectory: true)
            try FileManager.default.createDirectory(at: entriesDir, withIntermediateDirectories: true)

            for entry in period.entries.sorted(by: { $0.date < $1.date }) {
                let dateStr = entry.date.formatted(.iso8601.year().month().day())
                let mood = entry.mood?.label ?? ""
                let moodLine = mood.isEmpty ? "" : "\n心情: \(entry.mood!.emoji) \(mood)\n"
                let text = "# \(entry.date.formatted(date: .long, time: .omitted))\n\(moodLine)\n\(entry.content)\n"
                try text.write(to: entriesDir.appendingPathComponent("\(dateStr).md"), atomically: true, encoding: .utf8)

                // Copy attachments
                if !entry.attachments.isEmpty {
                    let attachDir = entriesDir.appendingPathComponent("\(dateStr)_附件", isDirectory: true)
                    try FileManager.default.createDirectory(at: attachDir, withIntermediateDirectories: true)
                    for att in entry.attachments {
                        let srcURL = AttachmentManager.fullURL(for: att.relativePath)
                        let dstURL = attachDir.appendingPathComponent(att.fileName ?? att.relativePath)
                        if FileManager.default.fileExists(atPath: srcURL.path) {
                            try FileManager.default.copyItem(at: srcURL, to: dstURL)
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private static func exportReports(context: ModelContext, to baseURL: URL) throws {
        let descriptor = FetchDescriptor<AnalysisReport>(sortBy: [SortDescriptor(\.createdAt)])
        let reports = try context.fetch(descriptor)

        guard !reports.isEmpty else { return }

        let reportsDir = baseURL.appendingPathComponent("分析报告", isDirectory: true)
        try FileManager.default.createDirectory(at: reportsDir, withIntermediateDirectories: true)

        for report in reports {
            let dateStr = report.createdAt.formatted(.iso8601.year().month().day())
            let safeName = report.title.replacingOccurrences(of: "/", with: "-").prefix(50)
            let text = "# \(report.title)\n\n> 类型: \(report.type.displayName)\n> 生成时间: \(report.createdAt.formatted())\n\n\(report.content)\n"
            try text.write(to: reportsDir.appendingPathComponent("\(dateStr)_\(safeName).md"), atomically: true, encoding: .utf8)
        }
    }
}
