/// Keys and identifiers shared between Flutter and native home-screen widgets.
abstract final class WidgetConstants {
  static const appGroupId = 'group.com.bangguoxiong.bpCompanion';
  static const recordsKey = 'bp_records_v1';
  static const widgetDraftSysKey = 'widget_draft_sys';
  static const widgetDraftDiaKey = 'widget_draft_dia';
  static const widgetDraftPulseKey = 'widget_draft_pulse';
  static const widgetLastMessageKey = 'widget_last_message';

  /// Android `HomeWidgetProvider` / iOS WidgetKit kind identifier.
  static const widgetName = 'BpHomeWidget';
  static const androidWidgetClass =
      'com.bpcompanion.bp_companion.BpHomeWidgetProvider';
}
