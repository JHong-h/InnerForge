import Foundation
import SwiftData

// MARK: - Attachment

@Model
public final class Attachment {
    public var id: UUID
    public var relativePath: String
    public var thumbnailPath: String?
    public var fileName: String
    public var fileSize: Int64
    public var createdAt: Date

    public var entry: DailyEntry?

    public init(
        relativePath: String,
        thumbnailPath: String? = nil,
        fileName: String,
        fileSize: Int64 = 0,
        entry: DailyEntry? = nil
    ) {
        self.id = UUID()
        self.relativePath = relativePath
        self.thumbnailPath = thumbnailPath
        self.fileName = fileName
        self.fileSize = fileSize
        self.createdAt = Date()
        self.entry = entry
    }
}
