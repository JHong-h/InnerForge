import SwiftUI
import SwiftData
import IFCore

struct ContentView: View {
    @State private var selectedSection: SidebarSection? = .observations
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            NavigationSplitView {
                SidebarView(selection: $selectedSection)
            } detail: {
                switch selectedSection {
                case .observations:
                    ObservationListView()
                case .reports:
                    ReportListView()
                case .settings:
                    AISettingsView()
                case .none:
                    Text("选择一个栏目开始")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 800, minHeight: 550)
            .onReceive(NotificationCenter.default.publisher(for: .menuNewPeriod)) { _ in
                selectedSection = .observations
            }
            .onReceive(NotificationCenter.default.publisher(for: .menuNewEntry)) { _ in
                selectedSection = .observations
            }
        } else {
            OnboardingView(isCompleted: $hasCompletedOnboarding)
        }
    }
}

enum SidebarSection: String, Hashable, CaseIterable {
    case observations = "观察期"
    case reports = "分析报告"
    case settings = "设置"

    var icon: String {
        switch self {
        case .observations: "eye"
        case .reports: "doc.text.magnifyingglass"
        case .settings: "gearshape"
        }
    }
}
