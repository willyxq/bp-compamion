import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../models/bp_classification.dart';
import '../models/bp_record.dart';
import '../models/plan_task.dart';
import '../state/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final latest = state.latest;
    final today = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(),
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 2),
                  const Text('轻松血压',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppThemeColors.seed.withValues(alpha: 0.15),
              child: const Icon(Icons.favorite, color: AppThemeColors.seed),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _LatestCard(latest: latest),
        const SizedBox(height: 16),
        _TodayPlanCard(state: state, day: today),
        const SizedBox(height: 16),
        _WeekTrendCard(state: state),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return '夜深了，注意休息';
    if (h < 11) return '早上好';
    if (h < 14) return '中午好';
    if (h < 18) return '下午好';
    return '晚上好';
  }
}

class AppThemeColors {
  static const seed = Color(0xFFE5532E);
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.latest});
  final BpRecord? latest;

  @override
  Widget build(BuildContext context) {
    if (latest == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: const [
              Icon(Icons.monitor_heart_outlined,
                  size: 40, color: Colors.black26),
              SizedBox(height: 12),
              Text('还没有血压记录',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('点击下方“记一笔”开始记录',
                  style: TextStyle(color: Colors.black45, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    final r = latest!;
    final level = r.level;
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              level.color.withValues(alpha: 0.92),
              level.color.withValues(alpha: 0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('最新血压',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(level.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${r.systolic}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        height: 1,
                        fontWeight: FontWeight.w800)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('/',
                      style: TextStyle(color: Colors.white70, fontSize: 34)),
                ),
                Text('${r.diastolic}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        height: 1,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('mmHg',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (r.pulse != null) ...[
                  const Icon(Icons.favorite,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('${r.pulse} bpm',
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 16),
                ],
                const Icon(Icons.schedule, color: Colors.white70, size: 15),
                const SizedBox(width: 4),
                Text(_fmt(r),
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(level.advice,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, height: 1.35)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(BpRecord r) {
    final t = r.time;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.month}月${t.day}日 ${two(t.hour)}:${two(t.minute)} · ${r.context.label}';
  }
}

class _TodayPlanCard extends StatelessWidget {
  const _TodayPlanCard({required this.state, required this.day});
  final AppState state;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final tasks = state.todayTasks;
    final done = state.todayDoneCount(day);
    final total = tasks.length;
    final ratio = total == 0 ? 0.0 : done / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('今日计划',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('$done / $total',
                    style: const TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: const Color(0xFFEDEFF1),
                color: AppThemeColors.seed,
              ),
            ),
            const SizedBox(height: 14),
            ...tasks.take(4).map((t) {
              final isDone = t.isDoneOn(day);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => state.toggleTaskDone(t.id, day),
                      child: Icon(
                        isDone
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isDone ? t.type.color : Colors.black26,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(t.type.icon, size: 18, color: t.type.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.title,
                        style: TextStyle(
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: isDone ? Colors.black38 : Colors.black87,
                        ),
                      ),
                    ),
                    Text(t.timeLabel,
                        style: const TextStyle(
                            color: Colors.black38, fontSize: 12)),
                  ],
                ),
              );
            }),
            if (tasks.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('还有 ${tasks.length - 4} 项，去“规划”查看',
                    style: const TextStyle(
                        color: Colors.black38, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekTrendCard extends StatelessWidget {
  const _WeekTrendCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final data = state.recordsWithin(7);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('近 7 天趋势',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: data.length < 2
                  ? const Center(
                      child: Text('记录满 2 条后显示趋势',
                          style: TextStyle(color: Colors.black38)))
                  : LineChart(_chartData(data)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _Legend(color: Color(0xFFE5532E), label: '收缩压'),
                SizedBox(width: 20),
                _Legend(color: Color(0xFF1E88E5), label: '舒张压'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _chartData(List<BpRecord> data) {
    final sys = <FlSpot>[];
    final dia = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      sys.add(FlSpot(i.toDouble(), data[i].systolic.toDouble()));
      dia.add(FlSpot(i.toDouble(), data[i].diastolic.toDouble()));
    }
    return LineChartData(
      minY: 50,
      maxY: 190,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 40,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: const Color(0xFFEDEFF1), strokeWidth: 1),
      ),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        _line(sys, const Color(0xFFE5532E)),
        _line(dia, const Color(0xFF1E88E5)),
      ],
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: color,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.08),
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
