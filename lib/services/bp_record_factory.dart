import 'dart:math';

import '../models/bp_record.dart';

/// Validation and record creation shared by the in-app sheet and widgets.
abstract final class BpRecordFactory {
  static const minSystolic = 50;
  static const maxSystolic = 300;
  static const minDiastolic = 30;
  static const maxDiastolic = 200;

  static bool isValid(int systolic, int diastolic) =>
      systolic >= minSystolic &&
      systolic <= maxSystolic &&
      diastolic >= minDiastolic &&
      diastolic <= maxDiastolic;

  static MeasureContext inferContext([DateTime? time]) {
    final t = time ?? DateTime.now();
    if (t.hour < 12) return MeasureContext.morning;
    if (t.hour >= 21) return MeasureContext.beforeBed;
    return MeasureContext.other;
  }

  static String newId([Random? rng]) {
    final random = rng ?? Random();
    return '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(99999)}';
  }

  static BpRecord create({
    required int systolic,
    required int diastolic,
    int? pulse,
    DateTime? time,
    MeasureContext? context,
    String note = '',
    Random? rng,
  }) {
    if (!isValid(systolic, diastolic)) {
      throw ArgumentError('Invalid blood pressure values: $systolic/$diastolic');
    }
    final when = time ?? DateTime.now();
    return BpRecord(
      id: newId(rng),
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      time: when,
      context: context ?? inferContext(when),
      note: note,
    );
  }

  /// Merge two record lists by id; when duplicate ids exist keep the newer time.
  static List<BpRecord> merge(List<BpRecord> a, List<BpRecord> b) {
    final map = <String, BpRecord>{};
    for (final record in [...a, ...b]) {
      final existing = map[record.id];
      if (existing == null || record.time.isAfter(existing.time)) {
        map[record.id] = record;
      }
    }
    return map.values.toList()..sort((x, y) => y.time.compareTo(x.time));
  }
}
