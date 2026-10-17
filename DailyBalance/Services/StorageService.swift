import Foundation
import SwiftData

struct StoragePaths: Sendable {
    let root: URL
    var photos: URL { root.appendingPathComponent("Photos", isDirectory: true) }
    var exports: URL { root.appendingPathComponent("Exports", isDirectory: true) }
    var database: URL { root.appendingPathComponent("Balance.store") }

    static func live() throws -> Self {
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                 appropriateFor: nil, create: true)
        let paths = Self(root: support.appendingPathComponent("DailyBalance", isDirectory: true))
        try paths.prepare()
        return paths
    }
    func prepare() throws {
        for url in [root, photos, exports] {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true,
                                                    attributes: [.protectionKey: FileProtectionType.complete])
            try Self.protect(url)
        }
    }
    static func protect(_ url: URL) throws {
        var mutableURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try mutableURL.setResourceValues(values)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
    }
    func audit() throws {
        try Self.protect(root)
        // Audit the directory and SQLite sidecars; photos are protected at creation.
        for url in try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) {
            try Self.protect(url)
        }
        guard try root.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true else {
            throw CocoaError(.fileWriteUnknown)
        }
    }
    @MainActor func container() throws -> ModelContainer {
        let schema = Schema([DailyEntry.self, MealEntry.self, AppSettings.self, BodyMeasurementEntry.self])
        let configuration = ModelConfiguration("DailyBalance", schema: schema, url: database, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        container.mainContext.autosaveEnabled = false
        try audit()
        return container
    }
}
