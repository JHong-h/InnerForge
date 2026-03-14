import Foundation
import SwiftData
import IFCore

// MARK: - SwiftData Container

public final class StorageManager: Sendable {
    public static let shared = StorageManager()

    public let modelContainer: ModelContainer

    private init() {
        let schema = Schema([
            AIModelConfig.self,
            ObservationPeriod.self,
            DailyEntry.self,
            Attachment.self,
            AnalysisReport.self,
            SkillRecord.self,
        ])
        let config = ModelConfiguration(
            "InnerForge",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
