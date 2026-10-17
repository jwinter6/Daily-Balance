import Foundation
import ImageIO
import UniformTypeIdentifiers

/// All decoding and disk access happen off the main actor. Re-encoding omits EXIF/GPS.
actor ImageStorageService {
    let directory: URL
    init(directory: URL) { self.directory = directory }

    func save(_ data: Data) throws -> String {
        guard data.count <= 60_000_000 else { throw BalanceError.photoTooLarge }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { throw BalanceError.invalidImage }
        let name = UUID().uuidString + ".jpg"
        let original = directory.appendingPathComponent(name)
        let thumb = thumbnailURL(name)
        do {
            try encode(source: source, pixels: 2000, quality: 0.82, to: original)
            try encode(source: source, pixels: 480, quality: 0.72, to: thumb)
            return name
        } catch {
            try? FileManager.default.removeItem(at: original)
            try? FileManager.default.removeItem(at: thumb)
            throw error
        }
    }
    private func encode(source: CGImageSource, pixels: Int, quality: Double, to url: URL) throws {
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceThumbnailMaxPixelSize: pixels,
            kCGImageSourceShouldCacheImmediately: true]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              let result = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(result, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw BalanceError.invalidImage }
        // New destination receives pixels only, never the original properties dictionary.
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw BalanceError.invalidImage }
        try (result as Data).write(to: url, options: [.atomic, .completeFileProtection])
        try StoragePaths.protect(url)
    }
    func read(_ name: String, thumbnail: Bool) throws -> Data {
        try Data(contentsOf: thumbnail ? thumbnailURL(name) : imageURL(name))
    }
    func imageURL(_ name: String) -> URL { directory.appendingPathComponent((name as NSString).lastPathComponent) }
    func thumbnailURL(_ name: String) -> URL { directory.appendingPathComponent("thumb_" + (name as NSString).lastPathComponent) }
    func delete(_ name: String) throws {
        for url in [imageURL(name), thumbnailURL(name)] where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
    /// Run only when no photo transaction is in flight; also repairs crash leftovers.
    func removeOrphans(referenced: Set<String>) throws {
        let keep = referenced.union(referenced.map { "thumb_" + $0 })
        for url in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        where !keep.contains(url.lastPathComponent) { try FileManager.default.removeItem(at: url) }
    }
}
