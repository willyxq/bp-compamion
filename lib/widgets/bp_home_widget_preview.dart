import 'package:flutter/material.dart';

import '../models/bp_classification.dart';
import '../models/bp_record.dart';
import '../theme.dart';

/// Flutter-rendered preview of the native home-screen widget layout.
/// Used for golden tests and design review on platforms without WidgetKit.
class BpHomeWidgetPreview extends StatelessWidget {
  const BpHomeWidgetPreview({
    super.key,
    this.latest,
    this.draftSys = 120,
    this.draftDia = 80,
    this.draftPulse = 72,
    this.lastMessage,
    this.compact = false,
  });

  final BpRecord? latest;
  final int draftSys;
  final int draftDia;
  final int draftPulse;
  final String? lastMessage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final level = BpClassifier.classify(draftSys, draftDia);
    return Material(
      color: const Color(0xFFF6F7F9),
      child: Container(
        width: compact ? 170 : 360,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EAED)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.seed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '轻松血压',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const Spacer(),
                if (latest != null)
                  Text(
                    '${latest!.systolic}/${latest!.diastolic}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: latest!.level.color,
                    ),
                  ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 12),
              Text(
                '快速记录',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (compact)
              _CompactValueRow(label: '高压', value: draftSys, color: level.color)
            else ...[
              _StepperRow(label: '收缩压', value: draftSys),
              const SizedBox(height: 6),
              _StepperRow(label: '舒张压', value: draftDia),
              const SizedBox(height: 6),
              _StepperRow(label: '心率', value: draftPulse, suffix: 'bpm'),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.seed,
                  disabledBackgroundColor: AppTheme.seed,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(compact ? '记录血压' : '保存'),
              ),
            ),
            if (lastMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                lastMessage!,
                style: TextStyle(fontSize: 11, color: level.color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    this.suffix = 'mmHg',
  });

  final String label;
  final int value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF5C5F66)),
          ),
        ),
        _CircleButton(icon: Icons.remove),
        Expanded(
          child: Text(
            '$value $suffix',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1C1E),
            ),
          ),
        ),
        _CircleButton(icon: Icons.add),
      ],
    );
  }
}

class _CompactValueRow extends StatelessWidget {
  const _CompactValueRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: const Color(0xFF5C5F66)),
    );
  }
}
