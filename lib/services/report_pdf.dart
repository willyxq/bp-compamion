import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/bp_classification.dart';
import '../models/bp_record.dart';
import '../state/app_state.dart';

/// 生成「轻松血压」健康报告 PDF（含中文字体）。
class ReportPdf {
  /// 构建报告 PDF 字节流。[days] 为统计时间范围。
  static Future<Uint8List> build(AppState state, int days) async {
    // 中文字体：使用 Noto Sans SC（printing 包从 Google Fonts 下载并本地缓存，
    // 仅首次生成需联网，之后离线可用）。报告内容仅含中英文与数字，无需 emoji 字体。
    final base = await PdfGoogleFonts.notoSansSCRegular();
    final bold = await PdfGoogleFonts.notoSansSCBold();

    final doc = pw.Document(
      title: '轻松血压 · 健康报告',
      author: '轻松血压',
      theme: pw.ThemeData.withFont(base: base, bold: bold),
    );

    final stats = state.statsWithin(days);
    final records = state.recordsWithin(days).reversed.toList(); // 新→旧
    final now = DateTime.now();
    final from = now.subtract(Duration(days: days));

    PdfColor levelColor(BpLevel l) => PdfColor.fromInt(l.color.toARGB32());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text('轻松血压 · 健康报告',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey)),
              ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            '本报告由「轻松血压」自动生成，仅供健康管理参考，不能替代专业医疗诊断。第 ${ctx.pageNumber} / ${ctx.pagesCount} 页',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ),
        build: (ctx) => [
          // 标题区
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('血压健康报告',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '统计区间：${_d(from)} 至 ${_d(now)}（近 $days 天）',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.grey700),
                    ),
                    pw.Text('生成时间：${_dt(now)}',
                        style: const pw.TextStyle(
                            fontSize: 11, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE5532E),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text('轻松血压',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          pw.Divider(color: PdfColors.grey300, height: 28),

          if (stats.count == 0)
            pw.Text('所选区间内暂无血压记录。',
                style: const pw.TextStyle(color: PdfColors.grey700))
          else ...[
            // 概览卡片
            pw.Text('数据概览',
                style: pw.TextStyle(
                    fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                _metric('测量次数', '${stats.count}', '次'),
                _metric('平均血压',
                    '${stats.avgSystolic.round()}/${stats.avgDiastolic.round()}', 'mmHg'),
                _metric('达标率', '${(stats.normalRate * 100).round()}', '%'),
                _metric('平均心率',
                    stats.avgPulse == null ? '—' : '${stats.avgPulse!.round()}', 'bpm'),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _metric('收缩压范围',
                    '${stats.minSystolic}~${stats.maxSystolic}', 'mmHg'),
                _metric('舒张压范围',
                    '${stats.minDiastolic}~${stats.maxDiastolic}', 'mmHg'),
                pw.Expanded(flex: 2, child: pw.SizedBox()),
              ],
            ),
            pw.SizedBox(height: 22),

            // 分级分布
            pw.Text('血压分级分布',
                style: pw.TextStyle(
                    fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...BpLevel.values
                .map((l) => MapEntry(l, stats.levelDistribution[l] ?? 0))
                .where((e) => e.value > 0)
                .map((e) {
              final ratio = e.value / stats.count;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                        width: 80,
                        child: pw.Text(e.key.label,
                            style: const pw.TextStyle(fontSize: 10))),
                    pw.Expanded(
                      child: pw.Stack(
                        children: [
                          pw.Container(
                            height: 12,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                          ),
                          pw.Container(
                            height: 12,
                            width: 380 * ratio,
                            decoration: pw.BoxDecoration(
                              color: levelColor(e.key),
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.SizedBox(
                        width: 70,
                        child: pw.Text(
                            '${e.value} 次 · ${(ratio * 100).round()}%',
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 10))),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 22),

            // 明细表
            pw.Text('测量明细（共 ${records.length} 条）',
                style: pw.TextStyle(
                    fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _recordsTable(records, levelColor),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _metric(String title, String value, String unit) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.RichText(
              text: pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold),
                children: [
                  pw.TextSpan(
                      text: ' $unit',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _recordsTable(
      List<BpRecord> records, PdfColor Function(BpLevel) levelColor) {
    pw.Widget cell(String t,
            {bool header = false, PdfColor? color, pw.TextAlign? align}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
          child: pw.Text(t,
              textAlign: align ?? pw.TextAlign.left,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? PdfColors.black,
              )),
        );

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          cell('日期', header: true),
          cell('时间', header: true),
          cell('场景', header: true),
          cell('收缩压', header: true, align: pw.TextAlign.right),
          cell('舒张压', header: true, align: pw.TextAlign.right),
          cell('心率', header: true, align: pw.TextAlign.right),
          cell('分级', header: true),
        ],
      ),
    ];

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(
            color: i.isEven ? PdfColors.white : PdfColors.grey50),
        children: [
          cell(_d(r.time)),
          cell(_hm(r.time)),
          cell(r.context.label),
          cell('${r.systolic}', align: pw.TextAlign.right),
          cell('${r.diastolic}', align: pw.TextAlign.right),
          cell(r.pulse?.toString() ?? '—', align: pw.TextAlign.right),
          cell(r.level.label, color: levelColor(r.level)),
        ],
      ));
    }

    return pw.Table(
      border: pw.TableBorder.symmetric(
        inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.2),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.4),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(1.2),
        6: pw.FlexColumnWidth(1.8),
      },
      children: rows,
    );
  }

  static String _d(DateTime d) =>
      '${d.year}-${_pad(d.month)}-${_pad(d.day)}';
  static String _hm(DateTime d) => '${_pad(d.hour)}:${_pad(d.minute)}';
  static String _dt(DateTime d) => '${_d(d)} ${_hm(d)}';
  static String _pad(int n) => n.toString().padLeft(2, '0');
}
