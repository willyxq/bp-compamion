import 'dart:math';

import 'package:bp_companion/models/bp_record.dart';
import 'package:bp_companion/services/bp_record_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates blood pressure ranges', () {
    expect(BpRecordFactory.isValid(120, 80), isTrue);
    expect(BpRecordFactory.isValid(49, 80), isFalse);
    expect(BpRecordFactory.isValid(120, 29), isFalse);
    expect(BpRecordFactory.isValid(301, 80), isFalse);
  });

  test('creates record with inferred context', () {
    final record = BpRecordFactory.create(
      systolic: 118,
      diastolic: 76,
      rng: _FakeRandom(),
    );
    expect(record.systolic, 118);
    expect(record.diastolic, 76);
    expect(record.id, contains('_'));
  });

  test('merge keeps unique ids and prefers newer time', () {
    final older = BpRecord(
      id: 'same',
      systolic: 130,
      diastolic: 85,
      time: DateTime(2024, 1, 1),
    );
    final newer = BpRecord(
      id: 'same',
      systolic: 125,
      diastolic: 82,
      time: DateTime(2024, 6, 1),
    );
    final merged = BpRecordFactory.merge([older], [newer]);
    expect(merged, hasLength(1));
    expect(merged.first.systolic, 125);
  });
}

class _FakeRandom implements Random {
  @override
  int nextInt(int max) => 42;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.5;

  void nextBytes(List<int> buffer) {}
}
