import 'package:flutter/material.dart';

/// 血压分级，依据《中国高血压防治指南》诊室血压标准（mmHg）。
enum BpLevel {
  low, // 低血压 < 90/60
  normal, // 正常 < 120 且 < 80
  elevated, // 正常高值 120-139 或 80-89
  stage1, // 高血压 1 级 140-159 或 90-99
  stage2, // 高血压 2 级 160-179 或 100-109
  stage3, // 高血压 3 级 ≥180 或 ≥110
}

extension BpLevelInfo on BpLevel {
  String get label {
    switch (this) {
      case BpLevel.low:
        return '偏低';
      case BpLevel.normal:
        return '正常';
      case BpLevel.elevated:
        return '正常高值';
      case BpLevel.stage1:
        return '高血压 1 级';
      case BpLevel.stage2:
        return '高血压 2 级';
      case BpLevel.stage3:
        return '高血压 3 级';
    }
  }

  Color get color {
    switch (this) {
      case BpLevel.low:
        return const Color(0xFF42A5F5); // 蓝
      case BpLevel.normal:
        return const Color(0xFF2E9E6B); // 绿
      case BpLevel.elevated:
        return const Color(0xFFE0A100); // 黄
      case BpLevel.stage1:
        return const Color(0xFFEF7A1A); // 橙
      case BpLevel.stage2:
        return const Color(0xFFE5532E); // 深橙红
      case BpLevel.stage3:
        return const Color(0xFFD32F2F); // 红
    }
  }

  /// 是否达标（正常或正常高值视为基本可接受，低/高均需关注）。
  bool get isOk => this == BpLevel.normal;

  String get advice {
    switch (this) {
      case BpLevel.low:
        return '血压偏低，若伴头晕乏力请缓慢起身，必要时咨询医生。';
      case BpLevel.normal:
        return '血压理想，继续保持健康作息与规律监测。';
      case BpLevel.elevated:
        return '处于正常高值，建议低盐饮食、规律运动并加强监测。';
      case BpLevel.stage1:
        return '1 级高血压，请遵医嘱用药并坚持生活方式干预。';
      case BpLevel.stage2:
        return '2 级高血压，建议尽快就医评估并规范治疗。';
      case BpLevel.stage3:
        return '3 级高血压，风险较高，请及时就医；若有不适立即就诊。';
    }
  }
}

class BpClassifier {
  /// 按收缩压/舒张压取“较严重”的一级返回。
  static BpLevel classify(int systolic, int diastolic) {
    if (systolic < 90 || diastolic < 60) return BpLevel.low;

    final BpLevel sysLevel = _systolicLevel(systolic);
    final BpLevel diaLevel = _diastolicLevel(diastolic);
    return sysLevel.index >= diaLevel.index ? sysLevel : diaLevel;
  }

  static BpLevel _systolicLevel(int s) {
    if (s >= 180) return BpLevel.stage3;
    if (s >= 160) return BpLevel.stage2;
    if (s >= 140) return BpLevel.stage1;
    if (s >= 120) return BpLevel.elevated;
    return BpLevel.normal;
  }

  static BpLevel _diastolicLevel(int d) {
    if (d >= 110) return BpLevel.stage3;
    if (d >= 100) return BpLevel.stage2;
    if (d >= 90) return BpLevel.stage1;
    if (d >= 80) return BpLevel.elevated;
    return BpLevel.normal;
  }
}
