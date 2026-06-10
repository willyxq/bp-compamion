/// 从 OCR 或语音识别文本中解析血压读数。
class BpParsedValues {
  final int? systolic;
  final int? diastolic;
  final int? pulse;

  const BpParsedValues({this.systolic, this.diastolic, this.pulse});

  bool get hasBp => systolic != null && diastolic != null;
  bool get isComplete => hasBp && pulse != null;
}

class BpInputParser {
  static const _sysLabels = ['高压', '收缩压', 'systolic', 'sys', 'sbp'];
  static const _diaLabels = ['低压', '舒张压', 'diastolic', 'dia', 'dbp'];
  static const _pulseLabels = ['脉搏', '心率', 'pulse', 'hr', 'bpm'];

  /// 解析任意文本（OCR 或语音转写）。
  static BpParsedValues parse(String raw) {
    final text = _normalize(raw);
    if (text.isEmpty) return const BpParsedValues();

    final labeled = _parseLabeled(text);
    if (labeled.hasBp) return labeled;

    final slash = _parseSlash(text);
    if (slash.hasBp) return slash;

    final spoken = _parseSpokenChinese(text);
    if (spoken.hasBp) return spoken;

    return _parseNumberTriplet(text);
  }

  static String _normalize(String raw) {
    return raw
        .replaceAll('\n', ' ')
        .replaceAll('：', ':')
        .replaceAll('／', '/')
        .replaceAll('，', ',')
        .replaceAll('。', '.')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  static BpParsedValues _parseLabeled(String text) {
    int? sys = _valueAfterLabels(text, _sysLabels);
    int? dia = _valueAfterLabels(text, _diaLabels);
    int? pulse = _valueAfterLabels(text, _pulseLabels);

    // 标签在前：高压 134 / 134 mmhg 高压
    sys ??= _valueBeforeLabels(text, _sysLabels);
    dia ??= _valueBeforeLabels(text, _diaLabels);
    pulse ??= _valueBeforeLabels(text, _pulseLabels);

    return BpParsedValues(
      systolic: _validSystolic(sys),
      diastolic: _validDiastolic(dia),
      pulse: _validPulse(pulse),
    );
  }

  static int? _valueAfterLabels(String text, List<String> labels) {
    for (final label in labels) {
      final re = RegExp(
        '$label\\s*[:：]?\\s*(${_digitPattern()})',
        caseSensitive: false,
      );
      final m = re.firstMatch(text);
      if (m != null) return _parseNumberToken(m.group(1)!);
    }
    return null;
  }

  static int? _valueBeforeLabels(String text, List<String> labels) {
    for (final label in labels) {
      final re = RegExp(
        '(${_digitPattern()})\\s*(?:mmhg|mm\\s*hg|次/分|bpm)?\\s*$label',
        caseSensitive: false,
      );
      final m = re.firstMatch(text);
      if (m != null) return _parseNumberToken(m.group(1)!);
    }
    return null;
  }

  static BpParsedValues _parseSlash(String text) {
    final re = RegExp(
      '(${_digitPattern()})\\s*[/\\-]\\s*(${_digitPattern()})'
      '(?:\\s*[/\\-]\\s*(${_digitPattern()}))?',
      caseSensitive: false,
    );
    final m = re.firstMatch(text);
    if (m == null) return const BpParsedValues();

    final sys = _validSystolic(_parseNumberToken(m.group(1)!));
    final dia = _validDiastolic(_parseNumberToken(m.group(2)!));
    final pulse = m.group(3) != null
        ? _validPulse(_parseNumberToken(m.group(3)!))
        : null;

    if (sys != null && dia != null && sys > dia) {
      return BpParsedValues(systolic: sys, diastolic: dia, pulse: pulse);
    }
    return const BpParsedValues();
  }

  /// 口语：「高压一百三十四低压九十七脉搏六十三」
  static BpParsedValues _parseSpokenChinese(String text) {
    int? readAfter(String source, List<String> labels) {
      for (final label in labels) {
        final idx = source.indexOf(label);
        if (idx < 0) continue;
        final tail = source.substring(idx + label.length);
        final n = _parseChineseOrArabicNumber(tail);
        if (n != null) return n;
      }
      return null;
    }

    final sys = _validSystolic(readAfter(text, _sysLabels));
    final dia = _validDiastolic(readAfter(text, _diaLabels));
    final pulse = _validPulse(readAfter(text, _pulseLabels));

    return BpParsedValues(systolic: sys, diastolic: dia, pulse: pulse);
  }

  /// 从连续数字中推断（常见于血压计屏幕 OCR）。
  static BpParsedValues _parseNumberTriplet(String text) {
    final numbers = <int>[];
    final re = RegExp(_digitPattern());
    for (final m in re.allMatches(text)) {
      final n = _parseNumberToken(m.group(0)!);
      if (n != null) numbers.add(n);
    }

    for (var i = 0; i + 1 < numbers.length; i++) {
      final sys = numbers[i];
      final dia = numbers[i + 1];
      if (!_isPlausiblePair(sys, dia)) continue;

      int? pulse;
      if (i + 2 < numbers.length) {
        final p = numbers[i + 2];
        if (_validPulse(p) != null) pulse = p;
      }

      return BpParsedValues(systolic: sys, diastolic: dia, pulse: pulse);
    }

    return const BpParsedValues();
  }

  static String _digitPattern() =>
      r'(?:\d{2,3}|[零一二三四五六七八九十百千万两]+)';

  static int? _parseNumberToken(String token) {
    if (RegExp(r'^\d+$').hasMatch(token)) {
      return int.tryParse(token);
    }
    return _parseChineseOrArabicNumber(token);
  }

  static int? _parseChineseOrArabicNumber(String source) {
    final trimmed = source.trim();
    final leadingDigits = RegExp(r'^(\d{2,3})').firstMatch(trimmed);
    if (leadingDigits != null) {
      return int.tryParse(leadingDigits.group(1)!);
    }

    final cn = RegExp(r'^([零一二三四五六七八九十百千万两]+)').firstMatch(trimmed);
    if (cn != null) {
      return _chineseToInt(cn.group(1)!);
    }
    return null;
  }

  static int? _chineseToInt(String s) {
    if (s.isEmpty) return null;
    const map = {
      '零': 0,
      '一': 1,
      '二': 2,
      '两': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };

    var section = 0;
    var number = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (map.containsKey(c)) {
        number = map[c]!;
      } else if (c == '十') {
        section += (number == 0 ? 1 : number) * 10;
        number = 0;
      } else if (c == '百') {
        section += (number == 0 ? 1 : number) * 100;
        number = 0;
      } else {
        return null;
      }
    }
    final value = section + number;
    return value > 0 ? value : null;
  }

  static bool _isPlausiblePair(int sys, int dia) {
    return _validSystolic(sys) != null &&
        _validDiastolic(dia) != null &&
        sys > dia;
  }

  static int? _validSystolic(int? v) =>
      v != null && v >= 50 && v <= 300 ? v : null;

  static int? _validDiastolic(int? v) =>
      v != null && v >= 30 && v <= 200 ? v : null;

  static int? _validPulse(int? v) =>
      v != null && v >= 30 && v <= 220 ? v : null;
}
