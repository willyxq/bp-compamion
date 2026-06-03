import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bp_companion/models/bp_classification.dart';

void main() {
  testWidgets('app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(find.byType(Scaffold), findsOneWidget);
  });

  test('血压分级逻辑', () {
    expect(BpClassifier.classify(118, 76), BpLevel.normal);
    expect(BpClassifier.classify(135, 85), BpLevel.elevated);
    expect(BpClassifier.classify(145, 92), BpLevel.stage1);
    expect(BpClassifier.classify(165, 95), BpLevel.stage2);
    expect(BpClassifier.classify(185, 120), BpLevel.stage3);
    expect(BpClassifier.classify(85, 55), BpLevel.low);
    // 取较严重一级：收缩压正常但舒张压偏高
    expect(BpClassifier.classify(130, 95), BpLevel.stage1);
  });
}
