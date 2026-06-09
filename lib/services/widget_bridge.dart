import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import 'widget_platform.dart';

import '../models/bp_record.dart';
import 'bp_record_factory.dart';
import 'widget_constants.dart';

/// Syncs blood-pressure records with the App Group / HomeWidget shared store
/// so native widgets can read and write without launching the Flutter UI.
class WidgetBridge {
  static bool _initialized = false;

  static bool get isSupported => widgetPlatformSupported;

  Future<void> init() async {
    if (!isSupported || _initialized) return;
    await HomeWidget.setAppGroupId(WidgetConstants.appGroupId);
    _initialized = true;
  }

  Future<List<BpRecord>> loadSharedRecords() async {
    if (!isSupported) return [];
    await init();
    final raw = await HomeWidget.getWidgetData<String>(
      WidgetConstants.recordsKey,
      defaultValue: null,
    );
    if (raw == null || raw.isEmpty) return [];
    return _decodeRecords(raw);
  }

  Future<void> saveSharedRecords(List<BpRecord> records) async {
    if (!isSupported) return;
    await init();
    final raw = jsonEncode(records.map((e) => e.toJson()).toList());
    await HomeWidget.saveWidgetData<String>(WidgetConstants.recordsKey, raw);
    await _refreshWidget();
  }

  Future<void> appendSharedRecord(BpRecord record) async {
    final existing = await loadSharedRecords();
    existing.add(record);
    await saveSharedRecords(existing);
    await HomeWidget.saveWidgetData<String>(
      WidgetConstants.widgetLastMessageKey,
      '已保存 ${record.systolic}/${record.diastolic}',
    );
  }

  Future<void> saveDraft({int? sys, int? dia, int? pulse}) async {
    if (!isSupported) return;
    await init();
    if (sys != null) {
      await HomeWidget.saveWidgetData<int>(
        WidgetConstants.widgetDraftSysKey,
        sys,
      );
    }
    if (dia != null) {
      await HomeWidget.saveWidgetData<int>(
        WidgetConstants.widgetDraftDiaKey,
        dia,
      );
    }
    if (pulse != null) {
      await HomeWidget.saveWidgetData<int>(
        WidgetConstants.widgetDraftPulseKey,
        pulse,
      );
    }
    await _refreshWidget();
  }

  Future<void> _refreshWidget() async {
    await HomeWidget.updateWidget(
      name: WidgetConstants.widgetName,
      iOSName: WidgetConstants.widgetName,
      qualifiedAndroidName: WidgetConstants.androidWidgetClass,
    );
  }

  static List<BpRecord> _decodeRecords(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => BpRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Background entry point for Android widget interactions.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  final bridge = WidgetBridge();
  await bridge.init();
  if (uri == null) return;

  switch (uri.host) {
    case 'save':
      final sys = int.tryParse(uri.queryParameters['sys'] ?? '');
      final dia = int.tryParse(uri.queryParameters['dia'] ?? '');
      final pulse = int.tryParse(uri.queryParameters['pulse'] ?? '');
      if (sys == null || dia == null || !BpRecordFactory.isValid(sys, dia)) {
        return;
      }
      final record = BpRecordFactory.create(
        systolic: sys,
        diastolic: dia,
        pulse: pulse,
      );
      await bridge.appendSharedRecord(record);
    case 'adjust':
      final field = uri.queryParameters['field'];
      final delta = int.tryParse(uri.queryParameters['delta'] ?? '0') ?? 0;
      final sys = await HomeWidget.getWidgetData<int>(
        WidgetConstants.widgetDraftSysKey,
        defaultValue: 120,
      );
      final dia = await HomeWidget.getWidgetData<int>(
        WidgetConstants.widgetDraftDiaKey,
        defaultValue: 80,
      );
      final pulse = await HomeWidget.getWidgetData<int>(
        WidgetConstants.widgetDraftPulseKey,
        defaultValue: 72,
      );
      switch (field) {
        case 'sys':
          await bridge.saveDraft(sys: (sys ?? 120) + delta);
        case 'dia':
          await bridge.saveDraft(dia: (dia ?? 80) + delta);
        case 'pulse':
          await bridge.saveDraft(pulse: (pulse ?? 72) + delta);
      }
  }
}
