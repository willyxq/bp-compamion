import 'package:bp_companion/services/bp_input_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BpInputParser', () {
    test('解析欧姆龙血压计 OCR 文本（134/97/63）', () {
      const ocr = '''
OMRON
HEM-7121
134
97
63
高压 mmHg
低压 mmHg
脉搏 次/分
''';
      final v = BpInputParser.parse(ocr);
      expect(v.systolic, 134);
      expect(v.diastolic, 97);
      expect(v.pulse, 63);
    });

    test('解析带标签的文本', () {
      final v = BpInputParser.parse('高压 120 低压 80 脉搏 72');
      expect(v.systolic, 120);
      expect(v.diastolic, 80);
      expect(v.pulse, 72);
    });

    test('解析斜杠格式', () {
      final v = BpInputParser.parse('120/80/68');
      expect(v.systolic, 120);
      expect(v.diastolic, 80);
      expect(v.pulse, 68);
    });

    test('解析中文口语', () {
      final v = BpInputParser.parse('高压一百三十四低压九十七脉搏六十三');
      expect(v.systolic, 134);
      expect(v.diastolic, 97);
      expect(v.pulse, 63);
    });

    test('无效文本返回空', () {
      final v = BpInputParser.parse('今天天气不错');
      expect(v.hasBp, isFalse);
    });
  });
}
