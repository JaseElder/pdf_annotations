import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/presentation/widgets/pan_layer.dart';

void main() {
  testWidgets('PanLayer builds correctly and contains RawGestureDetector', (WidgetTester tester) async {
    final testKey = GlobalKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanLayer(
          gDKey: testKey,
          onDragStart: (details) {},
        ),
      ),
    );

    // Verify that the PanLayer wraps a RawGestureDetector with the assigned key
    expect(find.byType(RawGestureDetector), findsOneWidget);
    expect(find.byKey(testKey), findsOneWidget);
  });
}
