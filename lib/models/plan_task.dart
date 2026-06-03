import 'package:flutter/material.dart';

/// 计划/提醒类型。
enum TaskType {
  medication, // 服药
  measure, // 测量血压
  diet, // 饮食（低盐等）
  exercise, // 运动
  sleep, // 作息
  other, // 其他
}

extension TaskTypeInfo on TaskType {
  String get label {
    switch (this) {
      case TaskType.medication:
        return '服药';
      case TaskType.measure:
        return '测量';
      case TaskType.diet:
        return '饮食';
      case TaskType.exercise:
        return '运动';
      case TaskType.sleep:
        return '作息';
      case TaskType.other:
        return '其他';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskType.medication:
        return Icons.medication_outlined;
      case TaskType.measure:
        return Icons.favorite_outline;
      case TaskType.diet:
        return Icons.restaurant_outlined;
      case TaskType.exercise:
        return Icons.directions_run_outlined;
      case TaskType.sleep:
        return Icons.bedtime_outlined;
      case TaskType.other:
        return Icons.check_circle_outline;
    }
  }

  Color get color {
    switch (this) {
      case TaskType.medication:
        return const Color(0xFF7E57C2);
      case TaskType.measure:
        return const Color(0xFFE5532E);
      case TaskType.diet:
        return const Color(0xFF2E9E6B);
      case TaskType.exercise:
        return const Color(0xFF1E88E5);
      case TaskType.sleep:
        return const Color(0xFF5C6BC0);
      case TaskType.other:
        return const Color(0xFF78909C);
    }
  }
}

/// 一项每日计划/提醒。每天根据 [completedDates] 记录完成情况。
class PlanTask {
  final String id;
  final String title;
  final TaskType type;
  final int hour; // 提醒时间（24 小时制）
  final int minute;
  final bool enabled;

  /// 已完成的日期键集合（yyyy-MM-dd）。
  final Set<String> completedDates;

  PlanTask({
    required this.id,
    required this.title,
    required this.type,
    required this.hour,
    required this.minute,
    this.enabled = true,
    Set<String>? completedDates,
  }) : completedDates = completedDates ?? <String>{};

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isDoneOn(DateTime day) => completedDates.contains(dateKey(day));

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  PlanTask copyWith({
    String? title,
    TaskType? type,
    int? hour,
    int? minute,
    bool? enabled,
    Set<String>? completedDates,
  }) =>
      PlanTask(
        id: id,
        title: title ?? this.title,
        type: type ?? this.type,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        enabled: enabled ?? this.enabled,
        completedDates: completedDates ?? this.completedDates,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.index,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
        'completedDates': completedDates.toList(),
      };

  factory PlanTask.fromJson(Map<String, dynamic> json) => PlanTask(
        id: json['id'] as String,
        title: json['title'] as String,
        type: TaskType.values[(json['type'] as int?) ?? 5],
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        enabled: (json['enabled'] as bool?) ?? true,
        completedDates: ((json['completedDates'] as List?) ?? [])
            .map((e) => e as String)
            .toSet(),
      );
}
