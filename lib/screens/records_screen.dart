import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bp_classification.dart';
import '../models/bp_record.dart';
import '../state/app_state.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final records = state.records;

    if (records.isEmpty) {
      return const Center(
        child: Text('暂无记录，点击“记一笔”添加',
            style: TextStyle(color: Colors.black45)),
      );
    }

    final groups = _groupByDay(records);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: false,
          floating: true,
          title: Text('记录'),
          automaticallyImplyLeading: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          sliver: SliverList.builder(
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final entry = groups[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 0, 8),
                    child: Text(entry.key,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black54)),
                  ),
                  Card(
                    child: Column(
                      children: [
                        for (int j = 0; j < entry.value.length; j++) ...[
                          _RecordTile(record: entry.value[j]),
                          if (j != entry.value.length - 1)
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        ]
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<MapEntry<String, List<BpRecord>>> _groupByDay(List<BpRecord> records) {
    final map = <String, List<BpRecord>>{};
    final now = DateTime.now();
    for (final r in records) {
      final d = r.time;
      String key;
      if (_sameDay(d, now)) {
        key = '今天';
      } else if (_sameDay(d, now.subtract(const Duration(days: 1)))) {
        key = '昨天';
      } else {
        key = '${d.year}年${d.month}月${d.day}日';
      }
      map.putIfAbsent(key, () => []).add(r);
    }
    return map.entries.toList();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final BpRecord record;

  @override
  Widget build(BuildContext context) {
    final level = record.level;
    final t = record.time;
    String two(int n) => n.toString().padLeft(2, '0');
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) =>
          context.read<AppState>().deleteRecord(record.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: level.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${record.systolic}/${record.diastolic}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Text('mmHg',
                        style: TextStyle(
                            fontSize: 12, color: Colors.black38)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${two(t.hour)}:${two(t.minute)} · ${record.context.label}'
                  '${record.pulse != null ? ' · ${record.pulse} bpm' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: level.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(level.label,
                  style: TextStyle(
                      color: level.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
