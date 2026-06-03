import 'dart:math';

import 'package:flutter/material.dart';

import '../models/bp_classification.dart';
import '../models/bp_record.dart';
import '../models/plan_task.dart';
import '../services/storage.dart';

/// 一段时间内的血压统计结果。
class BpStats {
  final int count;
  final double avgSystolic;
  final double avgDiastolic;
  final double? avgPulse;
  final int minSystolic;
  final int maxSystolic;
  final int minDiastolic;
  final int maxDiastolic;
  final double normalRate; // 达标率（正常占比）
  final Map<BpLevel, int> levelDistribution;

  const BpStats({
    required this.count,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.avgPulse,
    required this.minSystolic,
    required this.maxSystolic,
    required this.minDiastolic,
    required this.maxDiastolic,
    required this.normalRate,
    required this.levelDistribution,
  });

  static const empty = BpStats(
    count: 0,
    avgSystolic: 0,
    avgDiastolic: 0,
    avgPulse: null,
    minSystolic: 0,
    maxSystolic: 0,
    minDiastolic: 0,
    maxDiastolic: 0,
    normalRate: 0,
    levelDistribution: {},
  );
}

class AppState extends ChangeNotifier {
  AppState(this._storage);

  final Storage _storage;
  final _rng = Random();

  List<BpRecord> _records = [];
  List<PlanTask> _tasks = [];
  bool _loading = true;

  bool get loading => _loading;

  /// 记录按时间倒序。
  List<BpRecord> get records =>
      [..._records]..sort((a, b) => b.time.compareTo(a.time));

  List<PlanTask> get tasks =>
      [..._tasks]..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

  BpRecord? get latest => records.isEmpty ? null : records.first;

  Future<void> init() async {
    _records = await _storage.loadRecords();
    _tasks = await _storage.loadTasks();
    if (!await _storage.isSeeded() && _records.isEmpty && _tasks.isEmpty) {
      _seed();
      await _storage.markSeeded();
      await _persist();
    }
    _loading = false;
    notifyListeners();
  }

  // ---- 记录操作 ----
  Future<void> addRecord(BpRecord record) async {
    _records.add(record);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _persist();
    notifyListeners();
  }

  // ---- 计划操作 ----
  Future<void> addTask(PlanTask task) async {
    _tasks.add(task);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> updateTask(PlanTask task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i >= 0) _tasks[i] = task;
    await _persist();
    notifyListeners();
  }

  Future<void> toggleTaskDone(String id, DateTime day) async {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final key = PlanTask.dateKey(day);
    final set = {..._tasks[i].completedDates};
    if (set.contains(key)) {
      set.remove(key);
    } else {
      set.add(key);
    }
    _tasks[i] = _tasks[i].copyWith(completedDates: set);
    await _persist();
    notifyListeners();
  }

  // ---- 派生数据 ----
  List<PlanTask> get todayTasks =>
      tasks.where((t) => t.enabled).toList();

  int todayDoneCount(DateTime day) =>
      todayTasks.where((t) => t.isDoneOn(day)).length;

  /// 取最近 [days] 天内的记录（按时间升序）。
  List<BpRecord> recordsWithin(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final list = _records.where((r) => r.time.isAfter(cutoff)).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  BpStats statsWithin(int days) {
    final list = recordsWithin(days);
    if (list.isEmpty) return BpStats.empty;

    int sumS = 0, sumD = 0, sumP = 0, pulseCount = 0;
    int minS = 999, maxS = 0, minD = 999, maxD = 0, normal = 0;
    final dist = <BpLevel, int>{};
    for (final r in list) {
      sumS += r.systolic;
      sumD += r.diastolic;
      if (r.pulse != null) {
        sumP += r.pulse!;
        pulseCount++;
      }
      minS = min(minS, r.systolic);
      maxS = max(maxS, r.systolic);
      minD = min(minD, r.diastolic);
      maxD = max(maxD, r.diastolic);
      if (r.level == BpLevel.normal) normal++;
      dist[r.level] = (dist[r.level] ?? 0) + 1;
    }
    return BpStats(
      count: list.length,
      avgSystolic: sumS / list.length,
      avgDiastolic: sumD / list.length,
      avgPulse: pulseCount == 0 ? null : sumP / pulseCount,
      minSystolic: minS,
      maxSystolic: maxS,
      minDiastolic: minD,
      maxDiastolic: maxD,
      normalRate: normal / list.length,
      levelDistribution: dist,
    );
  }

  Future<void> _persist() async {
    await _storage.saveRecords(_records);
    await _storage.saveTasks(_tasks);
  }

  String _id() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_rng.nextInt(99999)}';

  /// 首次启动写入演示数据，让界面有内容可看。
  void _seed() {
    final now = DateTime.now();
    // 最近 14 天，每天早晚各一条，模拟轻度高血压逐步改善。
    for (int d = 13; d >= 0; d--) {
      final base = 150 - (13 - d) * 1.2; // 收缩压缓慢下降
      final day = now.subtract(Duration(days: d));
      _records.add(BpRecord(
        id: _id(),
        systolic: (base + _rng.nextInt(8) - 2).round(),
        diastolic: (92 - (13 - d) * 0.6 + _rng.nextInt(6) - 2).round(),
        pulse: 70 + _rng.nextInt(12),
        time: DateTime(day.year, day.month, day.day, 7, 10),
        context: MeasureContext.morning,
        note: '',
      ));
      _records.add(BpRecord(
        id: _id(),
        systolic: (base - 4 + _rng.nextInt(8) - 2).round(),
        diastolic: (88 - (13 - d) * 0.5 + _rng.nextInt(6) - 2).round(),
        pulse: 68 + _rng.nextInt(10),
        time: DateTime(day.year, day.month, day.day, 21, 30),
        context: MeasureContext.beforeBed,
        note: '',
      ));
    }

    _tasks.addAll([
      PlanTask(id: _id(), title: '晨起测量血压', type: TaskType.measure, hour: 7, minute: 0),
      PlanTask(id: _id(), title: '服用降压药', type: TaskType.medication, hour: 8, minute: 0),
      PlanTask(id: _id(), title: '低盐饮食（每日<5g）', type: TaskType.diet, hour: 12, minute: 0),
      PlanTask(id: _id(), title: '快走/有氧运动 30 分钟', type: TaskType.exercise, hour: 18, minute: 0),
      PlanTask(id: _id(), title: '睡前测量血压', type: TaskType.measure, hour: 21, minute: 30),
      PlanTask(id: _id(), title: '规律作息，23点前入睡', type: TaskType.sleep, hour: 23, minute: 0),
    ]);
  }
}
