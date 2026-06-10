import AppIntents
import WidgetKit

@available(iOS 17.0, *)
struct LogBpIntent: AppIntent {
    static var title: LocalizedStringResource = "记录血压"
    static var description = IntentDescription("在不打开 App 的情况下快速记录一次血压。")

    @Parameter(title: "收缩压 (mmHg)", default: 120)
    var systolic: Int

    @Parameter(title: "舒张压 (mmHg)", default: 80)
    var diastolic: Int

    @Parameter(title: "心率 (可选)")
    var pulse: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("记录 \(\.$systolic)/\(\.$diastolic) 心率 \(\.$pulse)")
    }

    func perform() async throws -> some IntentResult {
        try BpSharedStore.appendRecord(
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse
        )
        WidgetCenter.shared.reloadTimelines(ofKind: "BpHomeWidget")
        return .result(dialog: "已保存 \(systolic)/\(diastolic)")
    }
}
