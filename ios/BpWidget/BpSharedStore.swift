import Foundation

enum BpSharedStore {
    static let appGroupId = "group.com.bangguoxiong.bpCompanion"
    static let recordsKey = "bp_records_v1"
    static let lastMessageKey = "widget_last_message"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    struct StoredRecord: Codable {
        let id: String
        let systolic: Int
        let diastolic: Int
        let pulse: Int?
        let time: String
        let context: Int
        let note: String
    }

    static func loadRecords() -> [StoredRecord] {
        guard let raw = defaults?.string(forKey: recordsKey),
              let data = raw.data(using: .utf8),
              let records = try? JSONDecoder().decode([StoredRecord].self, from: data) else {
            return []
        }
        return records
    }

    static func latestRecord() -> StoredRecord? {
        loadRecords().sorted { $0.time > $1.time }.first
    }

    static func appendRecord(systolic: Int, diastolic: Int, pulse: Int?) throws {
        guard systolic >= 50, systolic <= 300, diastolic >= 30, diastolic <= 200 else {
            throw NSError(domain: "BpSharedStore", code: 1)
        }

        var records = loadRecords()
        let now = Date()
        let context: Int
        let hour = Calendar.current.component(.hour, from: now)
        if hour < 12 {
            context = 0
        } else if hour >= 21 {
            context = 1
        } else {
            context = 4
        }

        let id = "\(Int(now.timeIntervalSince1970 * 1_000_000))_\(Int.random(in: 0..<99999))"
        let formatter = ISO8601DateFormatter()

        let record = StoredRecord(
            id: id,
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse,
            time: formatter.string(from: now),
            context: context,
            note: ""
        )
        records.append(record)

        let data = try JSONEncoder().encode(records)
        guard let json = String(data: data, encoding: .utf8) else { return }
        defaults?.set(json, forKey: recordsKey)
        defaults?.set("已保存 \(systolic)/\(diastolic)", forKey: lastMessageKey)
    }
}
