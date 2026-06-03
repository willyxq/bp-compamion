import 'bp_classification.dart';

/// 测量场景，影响读数解读（如晨峰血压）。
enum MeasureContext {
  morning, // 晨起
  beforeBed, // 睡前
  afterMed, // 服药后
  beforeMed, // 服药前
  other, // 其他
}

extension MeasureContextLabel on MeasureContext {
  String get label {
    switch (this) {
      case MeasureContext.morning:
        return '晨起';
      case MeasureContext.beforeBed:
        return '睡前';
      case MeasureContext.afterMed:
        return '服药后';
      case MeasureContext.beforeMed:
        return '服药前';
      case MeasureContext.other:
        return '其他';
    }
  }
}

/// 一条血压测量记录。
class BpRecord {
  final String id;
  final int systolic; // 收缩压 (高压) mmHg
  final int diastolic; // 舒张压 (低压) mmHg
  final int? pulse; // 心率 bpm
  final DateTime time;
  final MeasureContext context;
  final String note;

  const BpRecord({
    required this.id,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    required this.time,
    this.context = MeasureContext.other,
    this.note = '',
  });

  BpLevel get level => BpClassifier.classify(systolic, diastolic);

  Map<String, dynamic> toJson() => {
        'id': id,
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
        'time': time.toIso8601String(),
        'context': context.index,
        'note': note,
      };

  factory BpRecord.fromJson(Map<String, dynamic> json) => BpRecord(
        id: json['id'] as String,
        systolic: json['systolic'] as int,
        diastolic: json['diastolic'] as int,
        pulse: json['pulse'] as int?,
        time: DateTime.parse(json['time'] as String),
        context: MeasureContext.values[(json['context'] as int?) ?? 4],
        note: (json['note'] as String?) ?? '',
      );
}
