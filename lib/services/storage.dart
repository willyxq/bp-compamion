import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bp_record.dart';
import '../models/plan_task.dart';

/// 基于 shared_preferences 的本地 JSON 持久化。
class Storage {
  static const _kRecords = 'bp_records_v1';
  static const _kTasks = 'plan_tasks_v1';
  static const _kSeeded = 'seeded_v1';

  Future<List<BpRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRecords);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => BpRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRecords(List<BpRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(_kRecords, raw);
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
}
