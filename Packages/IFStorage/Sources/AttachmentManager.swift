import Foundation
import AppKit
import IFCore

// MARK: - Attachment File Manager

public enum AttachmentManager {
    private static var baseURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("InnerForge/Attachments", isDirectory: true)
    }

    public static func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    public static func saveImage(_ image: NSImage, entryId: UUID) throws -> (relativePath: String, thumbnailPath: String?) {
        try ensureDirectory()

        let fileName = "\(entryId.uuidString)_\(UUID().uuidString.prefix(8)).jpg"
        let relativePath = fileName
        let fullURL = baseURL.appendingPathComponent(fileName)

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.85])
        else {
            throw AttachmentError.imageConversionFailed
        }
        try jpegData.write(to: fullURL)

        // Generate thumbnail
        let thumbName = "thumb_\(fileName)"
        let thumbURL = baseURL.appendingPathComponent(thumbName)
        let thumbSize = NSSize(width: 200, height: 200)
        let thumbImage = NSImage(size: thumbSize)
        thumbImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy, fraction: 1.0)
        thumbImage.unlockFocus()

        if let thumbTiff = thumbImage.tiffRepresentation,
           let thumbBitmap = NSBitmapImageRep(data: thumbTiff),
           let thumbData = thumbBitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) {
            try thumbData.write(to: thumbURL)
            return (relativePath, thumbName)
        }

        return (relativePath, nil)
    }

    public static func fullURL(for relativePath: String) -> URL {
        baseURL.appendingPathComponent(relativePath)
    }

    public static func deleteFile(relativePath: String) {
        let url = baseURL.appendingPathComponent(relativePath)
        try? FileManager.default.removeItem(at: url)
    }
}

public enum AttachmentError: LocalizedError {
    case imageConversionFailed

    public var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "图片转换失败"
        }
    }
}
