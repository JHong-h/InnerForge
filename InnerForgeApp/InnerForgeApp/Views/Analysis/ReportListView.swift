import SwiftUI
import SwiftData
import IFCore

struct ReportListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AnalysisReport.createdAt, order: .reverse) private var reports: [AnalysisReport]
    @State private var selectedReport: AnalysisReport?
    @State private var filterType: ReportType?

    var body: some View {
        NavigationStack {
            Group {
                if reports.isEmpty {
                    ContentUnavailableView {
                        Label("暂无分析报告", systemImage: "doc.text.magnifyingglass")
                    } description: {
                        Text("在日记中触发「AI 洞察」或结束观察期后生成报告")
                    }
                } else {
                    List(filteredReports, selection: $selectedReport) { report in
                        NavigationLink(value: report) {
                            ReportRow(report: report)
                        }
                    }
                }
            }
            .navigationTitle("分析报告")
            .toolbar {
                ToolbarItem {
                    Picker("筛选", selection: $filterType) {
                        Text("全部").tag(nil as ReportType?)
                        ForEach([ReportType.dailyInsight, .periodSummary, .restructurePlan], id: \.self) { type in
                            Text(type.displayName).tag(type as ReportType?)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationDestination(for: AnalysisReport.self) { report in
                ReportDetailView(report: report)
            }
        }
    }

    private var filteredReports: [AnalysisReport] {
        guard let filterType else { return reports }
        return reports.filter { $0.type == filterType }
    }
}

private struct ReportRow: View {
    let report: AnalysisReport

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(report.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer()
                typeBadge
            }
            HStack {
                Text(report.createdAt, style: .date)
                Text("·")
                Text(report.createdAt, style: .time)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var typeBadge: some View {
        let (text, color): (String, Color) = {
            switch report.type {
            case .dailyInsight: return ("洞察", .green)
            case .periodSummary: return ("总结", .blue)
            case .restructurePlan: return ("重构", .purple)
            }
        }()
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
