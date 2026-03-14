import SwiftUI
import SwiftData
import IFCore

struct ObservationListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = ObservationViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.periods.isEmpty {
                    ContentUnavailableView {
                        Label("开始你的自我观察之旅", systemImage: "eye.circle")
                    } description: {
                        Text("创建一个观察期，每天记录你的行为和想法")
                    } actions: {
                        Button("创建观察期") { vm.isShowingNewPeriod = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(vm.periods, selection: $vm.selectedPeriod) { period in
                        NavigationLink(value: period) {
                            PeriodRow(period: period)
                        }
                        .contextMenu {
                            if period.status == .active {
                                Button("结束观察期") { vm.endPeriod(period) }
                            }
                            Button("删除", role: .destructive) { vm.deletePeriod(period) }
                        }
                    }
                }
            }
            .navigationTitle("观察期")
            .toolbar {
                Button("新建", systemImage: "plus") {
                    vm.isShowingNewPeriod = true
                }
            }
            .navigationDestination(for: ObservationPeriod.self) { period in
                ObservationDetailView(period: period)
            }
        }
        .onAppear { vm.load(context: modelContext) }
        .sheet(isPresented: $vm.isShowingNewPeriod) {
            NewObservationView(vm: vm)
        }
    }
}

private struct PeriodRow: View {
    let period: ObservationPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(period.title).font(.headline)
                Spacer()
                statusBadge
            }
            Text(period.intention)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack {
                Text("\(period.entries.count) 篇日记")
                Text("·")
                Text("第 \(period.daysElapsed)/\(period.totalPlannedDays) 天")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch period.status {
        case .active:
            Text("进行中")
                .font(.caption).padding(.horizontal, 6).padding(.vertical, 1)
                .background(.green.opacity(0.15)).foregroundStyle(.green).clipShape(Capsule())
        case .paused:
            Text("已暂停")
                .font(.caption).padding(.horizontal, 6).padding(.vertical, 1)
                .background(.orange.opacity(0.15)).foregroundStyle(.orange).clipShape(Capsule())
        case .completed:
            Text("已完成")
                .font(.caption).padding(.horizontal, 6).padding(.vertical, 1)
                .background(.blue.opacity(0.15)).foregroundStyle(.blue).clipShape(Capsule())
        case .archived:
            Text("已归档")
                .font(.caption).padding(.horizontal, 6).padding(.vertical, 1)
                .background(.gray.opacity(0.15)).foregroundStyle(.gray).clipShape(Capsule())
        }
    }
}
