import SwiftUI
import SwiftData
import IFCore
import IFStorage
import IFSkillKit
import IFSkillBuiltin
import IFAI
import IFObservation
import IFAnalysis

@main
struct InnerForgeApp: App {
    let container: ModelContainer
    @State private var skillManager = SkillManager()

    init() {
        self.container = StorageManager.shared.modelContainer
        for skill in BuiltinSkills.all {
            skillManager.register(skill)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(skillManager)
        }
        .modelContainer(container)
        .commands {
            CommandGroup(after: .newItem) {
                Button("新建观察期") {
                    NotificationCenter.default.post(name: .menuNewPeriod, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("写今日日记") {
                    NotificationCenter.default.post(name: .menuNewEntry, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            CommandGroup(after: .importExport) {
                Button("导出所有数据...") {
                    let context = container.mainContext
                    DataExporter.exportAll(context: context)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }

        Settings {
            AISettingsView()
        }
        .modelContainer(container)
    }
}

extension Notification.Name {
    static let menuNewPeriod = Notification.Name("menuNewPeriod")
    static let menuNewEntry = Notification.Name("menuNewEntry")
}
