import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/text_insertion_point_notifier.dart';

void main() {
  group('TextInsertionPointNotifier', () {
    late TextInsertionPointNotifier notifier;

    setUp(() {
      notifier = TextInsertionPointNotifier(const Offset(10, 20));
    });

    test('should move the point by a delta', () {
      const delta = Offset(5, -5);
      notifier.moveByDelta(delta);
      expect(notifier.value, const Offset(15, 15));
    });

    test('should set the absolute position of the point', () {
      const point = Offset(100, 200);
      notifier.setAbsolute(point);
      expect(notifier.value, point);
    });
  });
}
