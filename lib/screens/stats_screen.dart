import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/bp_classification.dart';
import '../models/bp_record.dart';
import '../services/report_pdf.dart';
import '../state/app_state.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _days = 7;
  bool _exporting = false;
  static const _ranges = {7: '7天', 30: '30天', 90: '90天'};

  Future<void> _exportReport(AppState state) async {
    if (_exporting) return;
    if (state.statsWithin(_days).count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该时间段暂无数据，无法生成报告')),
      );
      return;
    }
    setState(() => _exporting = true);
    try {
      final bytes = await ReportPdf.build(state, _days);
      final fileName =
          '轻松血压健康报告_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';
      // 打开系统分享面板：保存到文件、转发（信息/微信等）、打印均可。
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成报告失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.statsWithin(_days);
    final data = state.recordsWithin(_days);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('统计分析',
                  style:
                      TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            ),
            FilledButton.tonalIcon(
              onPressed: _exporting ? null : () => _exportReport(state),
              icon: _exporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share, size: 18),
              label: Text(_exporting ? '生成中' : '导出报告'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<int>(
          segments: _ranges.entries
              .map((e) =>
                  ButtonSegment<int>(value: e.key, label: Text(e.value)))
              .toList(),
          selected: {_days},
          onSelectionChanged: (s) => setState(() => _days = s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 16),
        if (stats.count == 0)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('该时间段暂无数据',
                    style: TextStyle(color: Colors.black45)),
              ),
            ),
          )
        else ...[
          _AvgRow(stats: stats),
          const SizedBox(height: 16),
          _TrendCard(data: data),
          const SizedBox(height: 16),
          _DistributionCard(stats: stats),
        ],
      ],
    );
  }
}

class _AvgRow extends StatelessWidget {
  const _AvgRow({required this.stats});
  final BpStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: '平均血压',
            value:
                '${stats.avgSystolic.round()}/${stats.avgDiastolic.round()}',
            unit: 'mmHg',
            color: const Color(0xFFE5532E),
            icon: Icons.monitor_heart_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: '达标率',
            value: '${(stats.normalRate * 100).round()}',
            unit: '%',
            color: const Color(0xFF2E9E6B),
            icon: Icons.verified_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });
  final String title;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  const SizedBox(width: 4),
                  Text(unit,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black38)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.data});
  final List<BpRecord> data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('血压趋势',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: data.length < 2
                  ? const Center(
                      child: Text('记录满 2 条后显示趋势',
                          style: TextStyle(color: Colors.black38)))
                  : LineChart(_buildChart()),
            ),
            const SizedBox(height: 10),
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

  LineChartData _buildChart() {
    final sys = <FlSpot>[];
    final dia = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      sys.add(FlSpot(i.toDouble(), data[i].systolic.toDouble()));
      dia.add(FlSpot(i.toDouble(), data[i].diastolic.toDouble()));
    }
    final labelStep = (data.length / 4).ceil().clamp(1, data.length);
    return LineChartData(
      minY: 50,
      maxY: 190,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 30,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: const Color(0xFFEDEFF1), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 30,
            reservedSize: 32,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.black38)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: labelStep.toDouble(),
            reservedSize: 24,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= data.length) return const SizedBox.shrink();
              final d = data[i].time;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${d.month}/${d.day}',
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black38)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
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
        dotData: FlDotData(
          show: spots.length <= 14,
          getDotPainter: (s, p, b, idx) => FlDotCirclePainter(
              radius: 3, color: color, strokeWidth: 0),
        ),
        belowBarData:
            BarAreaData(show: true, color: color.withValues(alpha: 0.06)),
      );
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.stats});
  final BpStats stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.count;
    final entries = BpLevel.values
        .map((l) => MapEntry(l, stats.levelDistribution[l] ?? 0))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('分级分布',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('共 $total 次',
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            ...entries.map((e) {
              final ratio = e.value / total;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(e.key.label,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFEDEFF1),
                          color: e.key.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 36,
                      child: Text('${(ratio * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
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
