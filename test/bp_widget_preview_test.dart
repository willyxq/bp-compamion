import 'package:bp_companion/models/bp_record.dart';
import 'package:bp_companion/widgets/bp_home_widget_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders medium widget preview with draft values', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BpHomeWidgetPreview(
              draftSys: 120,
              draftDia: 80,
              draftPulse: 72,
              lastMessage: '已保存 120/80',
              latest: BpRecord(
                id: '1',
                systolic: 131,
                diastolic: 84,
                time: DateTime(2024, 6, 9, 8),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('轻松血压'), findsOneWidget);
    expect(find.text('131/84'), findsOneWidget);
    expect(find.text('120 mmHg'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
    expect(find.text('已保存 120/80'), findsOneWidget);
  });

  testWidgets('renders compact iOS-style preview', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: BpHomeWidgetPreview(
              compact: true,
              draftSys: 120,
              draftDia: 80,
            ),
          ),
        ),
      ),
    );

    expect(find.text('记录血压'), findsOneWidget);
    expect(find.text('高压 120'), findsOneWidget);
  });
}
