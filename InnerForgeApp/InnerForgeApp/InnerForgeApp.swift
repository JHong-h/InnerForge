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

        Settings {
            AISettingsView()
        }
        .modelContainer(container)
    }
}
