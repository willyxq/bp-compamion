import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bp_record.dart';
import '../models/plan_task.dart';
import 'bp_record_factory.dart';
import 'widget_bridge.dart';

/// 基于 shared_preferences 的本地 JSON 持久化，并与桌面小组件共享存储同步。
class Storage {
  Storage({WidgetBridge? widgetBridge})
      : _widgetBridge = widgetBridge ?? WidgetBridge();

  static const _kRecords = 'bp_records_v1';
  static const _kTasks = 'plan_tasks_v1';
  static const _kSeeded = 'seeded_v1';
  static const _kMigratedToWidget = 'widget_storage_migrated_v1';

  final WidgetBridge _widgetBridge;

  Future<void> initWidgetSync() async {
    await _widgetBridge.init();
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kMigratedToWidget) ?? false)) {
      final local = await _loadLocalRecords(prefs);
      final shared = await _widgetBridge.loadSharedRecords();
      final merged = BpRecordFactory.merge(local, shared);
      await _saveLocalRecords(prefs, merged);
      await _widgetBridge.saveSharedRecords(merged);
      await prefs.setBool(_kMigratedToWidget, true);
    }
  }

  Future<List<BpRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final local = await _loadLocalRecords(prefs);
    final shared = await _widgetBridge.loadSharedRecords();
    final merged = BpRecordFactory.merge(local, shared);
    if (merged.length != local.length ||
        !_sameRecordIds(local, merged)) {
      await _saveLocalRecords(prefs, merged);
    }
    if (merged.length != shared.length ||
        !_sameRecordIds(shared, merged)) {
      await _widgetBridge.saveSharedRecords(merged);
    }
    return merged;
  }

  Future<void> saveRecords(List<BpRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveLocalRecords(prefs, records);
    await _widgetBridge.saveSharedRecords(records);
  }

  Future<List<PlanTask>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTasks);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PlanTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTasks(List<PlanTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await prefs.setString(_kTasks, raw);
  }

  Future<bool> isSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSeeded) ?? false;
  }

  Future<void> markSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeeded, true);
  }

  Future<List<BpRecord>> _loadLocalRecords(SharedPreferences prefs) async {
    final raw = prefs.getString(_kRecords);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => BpRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveLocalRecords(
    SharedPreferences prefs,
    List<BpRecord> records,
  ) async {
    final raw = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(_kRecords, raw);
  }

  bool _sameRecordIds(List<BpRecord> a, List<BpRecord> b) {
    if (a.length != b.length) return false;
    final idsA = a.map((r) => r.id).toSet();
    final idsB = b.map((r) => r.id).toSet();
    return idsA.length == idsB.length && idsA.containsAll(idsB);
  }
}
