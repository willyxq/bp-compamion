import SwiftUI
import WidgetKit

private let seedColor = Color(red: 0.90, green: 0.33, blue: 0.18)
private let textColor = Color(red: 0.10, green: 0.11, blue: 0.12)
private let mutedColor = Color(red: 0.36, green: 0.37, blue: 0.40)

struct BpWidgetEntry: TimelineEntry {
    let date: Date
    let latestSys: Int?
    let latestDia: Int?
    let lastMessage: String?
}

struct BpWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BpWidgetEntry {
        BpWidgetEntry(date: Date(), latestSys: 120, latestDia: 80, lastMessage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (BpWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BpWidgetEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> BpWidgetEntry {
        let latest = BpSharedStore.latestRecord()
        let message = UserDefaults(suiteName: BpSharedStore.appGroupId)?
            .string(forKey: BpSharedStore.lastMessageKey)
        return BpWidgetEntry(
            date: Date(),
            latestSys: latest?.systolic,
            latestDia: latest?.diastolic,
            lastMessage: message
        )
    }
}

struct BpWidgetEntryView: View {
    var entry: BpWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(red: 0.965, green: 0.969, blue: 0.976)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(seedColor).frame(width: 8, height: 8)
                    Text("轻松血压")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(textColor)
                    Spacer()
                    if let sys = entry.latestSys, let dia = entry.latestDia {
                        Text("\(sys)/\(dia)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(seedColor)
                    }
                }

                if family == .systemSmall {
                    Text("点按记录血压")
                        .font(.system(size: 12))
                        .foregroundStyle(mutedColor)
                } else {
                    Text("无需打开 App，即可快速记录一次测量。")
                        .font(.system(size: 11))
                        .foregroundStyle(mutedColor)
                }

                if #available(iOS 17.0, *) {
                    Button(intent: LogBpIntent()) {
                        Label("记录血压", systemImage: "plus.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(seedColor)
                }

                if let message = entry.lastMessage {
                    Text(message)
                        .font(.system(size: 10))
                        .foregroundStyle(seedColor)
                }
            }
            .padding(14)
        }
    }
}

struct BpHomeWidget: Widget {
    let kind: String = "BpHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BpWidgetProvider()) { entry in
            BpWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("轻松血压")
        .description("在桌面快速记录血压，无需打开 App。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
