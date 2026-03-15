import SwiftUI
import SwiftData
import IFCore
import IFSkillKit
import IFAI

struct ObservationDetailView: View {
    let period: ObservationPeriod
    @Environment(\.modelContext) private var modelContext
    @Environment(SkillManager.self) private var skillManager
    @State private var entryVM = EntryViewModel()
    @State private var analysisVM = AnalysisViewModel()
    @State private var aiSettingsVM = AISettingsViewModel()
    @State private var showEndConfirm = false

    var body: some View {
        HSplitView {
            // Left: entry list + calendar
            VStack(spacing: 0) {
                periodHeader
                Divider()
                entryList
            }
            .frame(minWidth: 240, idealWidth: 280)

            // Right: editor
            if let entry = entryVM.selectedEntry {
                DailyEntryEditorView(
                    entry: entry,
                    content: $entryVM.editContent,
                    mood: $entryVM.editMood,
                    onChanged: { entryVM.contentChanged() },
                    onSave: { entryVM.saveIfDirty() },
                    onAnalyze: { analyzeEntry(entry) },
                    onImageAdded: { image in entryVM.addImage(image) },
                    isAnalyzing: analysisVM.isAnalyzing
                )
            } else {
                ContentUnavailableView {
                    Label("选择或创建一篇日记", systemImage: "square.and.pencil")
                } description: {
                    Text("从左侧选择已有日记，或点击 + 创建今日日记")
                }
            }
        }
        .navigationTitle(period.title)
        .toolbar {
            ToolbarItemGroup {
                if period.status == .active {
                    Button("写今日日记", systemImage: "plus") {
                        entryVM.createTodayEntry(for: period)
                    }
                    Button("结束观察期", systemImage: "checkmark.circle") {
                        showEndConfirm = true
                    }
                }
                if period.status == .completed {
                    Menu("生成报告", systemImage: "doc.text.magnifyingglass") {
                        Button("观察期总结") { runPeriodSummary() }
                        Button("重构方案") { runRestructurePlan() }
                    }
                    .disabled(analysisVM.isAnalyzing)
                }
            }
        }
        .onAppear {
            entryVM.load(context: modelContext, period: period)
            analysisVM.load(context: modelContext, skillManager: skillManager)
            aiSettingsVM.load(context: modelContext)
        }
        .alert("确认结束观察期？", isPresented: $showEndConfirm) {
            Button("取消", role: .cancel) {}
            Button("结束") {
                period.status = .completed
                period.actualEndDate = Date()
                try? modelContext.save()
            }
        } message: {
            Text("结束后将无法添加新日记，但可以生成分析报告。")
        }
        .alert("未配置 AI 模型", isPresented: $showNoAIAlert) {
            Button("去设置") {
                // User navigates to settings manually
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请先在设置中添加一个 AI 模型配置。")
        }
        .alert("分析出错", isPresented: .init(
            get: { analysisVM.errorMessage != nil },
            set: { if !$0 { analysisVM.errorMessage = nil } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(analysisVM.errorMessage ?? "")
        }
    }

    private var periodHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(period.intention)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text("第 \(period.daysElapsed) 天 / 共 \(period.totalPlannedDays) 天")
                    .font(.caption2)
                Spacer()
                Text("\(period.entries.count) 篇")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            ProgressView(value: Double(period.daysElapsed), total: Double(max(1, period.totalPlannedDays)))
                .tint(period.isOverdue ? .orange : .accentColor)
        }
        .padding()
    }

    private var entryList: some View {
        List(entryVM.entries, selection: $entryVM.selectedEntry) { entry in
            EntryRow(entry: entry)
                .tag(entry)
                .contextMenu {
                    Button("删除", role: .destructive) { entryVM.deleteEntry(entry) }
                }
        }
        .onChange(of: entryVM.selectedEntry) { _, newValue in
            if let entry = newValue { entryVM.selectEntry(entry) }
        }
    }

    @State private var showNoAIAlert = false

    private func analyzeEntry(_ entry: DailyEntry) {
        guard let config = aiSettingsVM.defaultConfig else { showNoAIAlert = true; return }
        analysisVM.runDailyInsight(entry: entry, config: config)
    }

    private func runPeriodSummary() {
        guard let config = aiSettingsVM.defaultConfig else { showNoAIAlert = true; return }
        analysisVM.runPeriodSummary(period: period, config: config)
    }

    private func runRestructurePlan() {
        guard let config = aiSettingsVM.defaultConfig else { showNoAIAlert = true; return }
        analysisVM.runRestructurePlan(period: period, config: config)
    }
}

private struct EntryRow: View {
    let entry: DailyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.subheadline.bold())
                Spacer()
                if let mood = entry.mood {
                    Text(mood.emoji)
                }
            }
            Text(entry.content.prefix(60).replacingOccurrences(of: "\n", with: " "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}
