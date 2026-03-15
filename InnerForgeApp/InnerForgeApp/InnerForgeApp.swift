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
