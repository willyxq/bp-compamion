import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bp_classification.dart';
import '../models/bp_record.dart';
import '../services/bp_input_parser.dart';
import '../services/bp_ocr.dart';
import '../services/bp_voice_input.dart';
import '../state/app_state.dart';

Future<void> showAddRecordSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _AddRecordSheet(),
  );
}

class _AddRecordSheet extends StatefulWidget {
  const _AddRecordSheet();

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  final _sys = TextEditingController();
  final _dia = TextEditingController();
  final _pulse = TextEditingController();
  final _note = TextEditingController();
  MeasureContext _context = MeasureContext.morning;
  DateTime _time = DateTime.now();
  bool _busy = false;
  bool _listening = false;
  String _voiceHint = '';

  @override
  void dispose() {
    if (_listening) BpVoiceInput.stop();
    _sys.dispose();
    _dia.dispose();
    _pulse.dispose();
    _note.dispose();
    super.dispose();
  }

  void _applyParsed(BpParsedValues values, {String? sourceNote}) {
    setState(() {
      if (values.systolic != null) _sys.text = '${values.systolic}';
      if (values.diastolic != null) _dia.text = '${values.diastolic}';
      if (values.pulse != null) _pulse.text = '${values.pulse}';
      if (sourceNote != null && _note.text.trim().isEmpty) {
        _note.text = sourceNote;
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickPhotoSource() async {
    final supported = await BpOcr.isSupported;
    if (!mounted) return;
    if (!supported) {
      _showMessage('拍照识别请在 iOS/Android 手机 App 中使用');
      return;
    }

    final source = await showModalBottomSheet<ImageSourceKind>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍摄血压计屏幕'),
              onTap: () => Navigator.pop(ctx, ImageSourceKind.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, ImageSourceKind.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final values = switch (source) {
        ImageSourceKind.camera => await BpOcr.recognizeFromCamera(),
        ImageSourceKind.gallery => await BpOcr.recognizeFromGallery(),
      };
      _applyParsed(values, sourceNote: '拍照识别');
      _showMessage('已识别：${values.systolic}/${values.diastolic}'
          '${values.pulse != null ? '，脉搏 ${values.pulse}' : ''}');
    } on StateError catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('识别失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await BpVoiceInput.stop();
      setState(() {
        _listening = false;
        _voiceHint = '';
      });
      return;
    }

    setState(() {
      _listening = true;
      _voiceHint = '请说：高压一百三十四，低压九十七，脉搏六十三';
    });

    await BpVoiceInput.listen(
      onPartial: (text) {
        if (!mounted) return;
        setState(() => _voiceHint = text);
      },
      onResult: (values, transcript) {
        if (!mounted) return;
        _applyParsed(values, sourceNote: '语音识别');
        setState(() {
          _listening = false;
          _voiceHint = '';
        });
        _showMessage('已识别：$transcript');
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _voiceHint = '';
        });
        _showMessage(message);
      },
    );
  }

  BpLevel? get _previewLevel {
    final s = int.tryParse(_sys.text);
    final d = int.tryParse(_dia.text);
    if (s == null || d == null || s == 0 || d == 0) return null;
    return BpClassifier.classify(s, d);
  }

  void _save() {
    final s = int.tryParse(_sys.text);
    final d = int.tryParse(_dia.text);
    if (s == null || d == null || s < 50 || s > 300 || d < 30 || d > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的收缩压和舒张压')),
      );
      return;
    }
    final record = BpRecord(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}',
      systolic: s,
      diastolic: d,
      pulse: int.tryParse(_pulse.text),
      time: _time,
      context: _context,
      note: _note.text.trim(),
    );
    context.read<AppState>().addRecord(record);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存血压记录')),
    );
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _time,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    if (!mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time),
    );
    setState(() {
      _time = DateTime(date.year, date.month, date.day, t?.hour ?? _time.hour,
          t?.minute ?? _time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final level = _previewLevel;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('记录血压',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _pickPhotoSource,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_camera_outlined, size: 20),
                    label: const Text('拍照识别'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _toggleVoice,
                    icon: Icon(
                      _listening ? Icons.mic : Icons.mic_none_outlined,
                      size: 20,
                      color: _listening ? Colors.red : null,
                    ),
                    label: Text(_listening ? '停止' : '语音识别'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: _listening ? Colors.red : null,
                      side: _listening
                          ? const BorderSide(color: Colors.red)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            if (_listening && _voiceHint.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hearing, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _voiceHint,
                        style: const TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _numberField(_sys, '收缩压(高压)', 'mmHg'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numberField(_dia, '舒张压(低压)', 'mmHg'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _numberField(_pulse, '心率(可选)', 'bpm'),
            if (level != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: level.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: level.color),
                    const SizedBox(width: 8),
                    Text('分级：${level.label}',
                        style: TextStyle(
                            color: level.color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Text('测量场景',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MeasureContext.values.map((c) {
                final selected = c == _context;
                return ChoiceChip(
                  label: Text(c.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _context = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 20),
                    const SizedBox(width: 10),
                    Text(_formatTime(_time)),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.black38),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                hintText: '备注（如：服药后、运动后…）',
                filled: true,
                fillColor: const Color(0xFFF1F3F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('保存', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
      TextEditingController c, String label, String suffix) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: const Color(0xFFF1F3F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}  ${two(t.hour)}:${two(t.minute)}';
  }
}

enum ImageSourceKind { camera, gallery }
