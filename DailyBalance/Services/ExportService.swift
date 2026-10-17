import Foundation

struct ExportDocument: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let dailyEntries: [DailyValue]
    let meals: [MealValue]
    let bodyMeasurements: [BodyMeasurements]
}

enum ExportFormat: String, CaseIterable { case json = "JSON", csv = "CSV" }

@MainActor enum ExportService {
    static func create(format: ExportFormat, store: AppStore) throws -> URL {
        try store.clearExports()
        let data: Data
        switch format {
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            data = try encoder.encode(ExportDocument(schemaVersion: 2, exportedAt: Date(),
                                                     dailyEntries: store.entries, meals: store.meals,
                                                     bodyMeasurements: store.bodyMeasurements))
        case .csv:
            func quoted(_ text: String) -> String {
                // Spreadsheet formula injection prevention for user-entered notes.
                let safe = ["=", "+", "-", "@", "\t", "\r"].contains(where: { text.hasPrefix($0) }) ? "'" + text : text
                return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            }
            let header = "Datum;Gewicht_kg;Wohlbefinden;Energie;Schlaf;Hunger;Cravings;Notizen;Brustumfang_cm;Bauchumfang_cm;Po_Umfang_cm;Oberschenkel_links_cm;Oberschenkel_rechts_cm"
            let dailyByDay = Dictionary(uniqueKeysWithValues: store.entries.map { ($0.day, $0) })
            let bodyByDay = Dictionary(uniqueKeysWithValues: store.bodyMeasurements.map { ($0.day, $0) })
            let days = Set(dailyByDay.keys).union(bodyByDay.keys).sorted()
            let rows = days.map { day in
                let entry = dailyByDay[day]
                let weight = entry?.weight.map { String($0).replacingOccurrences(of: ".", with: ",") } ?? ""
                let ratings = Metric.allCases.map { metric in entry?[metric].map(String.init) ?? "" }
                let body = BodyMeasurement.allCases.map { measurement in
                    bodyByDay[day]?[measurement].map { String($0).replacingOccurrences(of: ".", with: ",") } ?? ""
                }
                return ([day.rawValue, weight] + ratings + [quoted(entry?.notes ?? "")] + body).joined(separator: ";")
            }
            data = Data(("\u{FEFF}" + ([header] + rows).joined(separator: "\r\n")).utf8)
        }
        let url = store.paths.exports.appendingPathComponent("DailyBalance.\(format.rawValue.lowercased())")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        try StoragePaths.protect(url)
        return url
    }
}
