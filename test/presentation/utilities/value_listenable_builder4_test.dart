import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/presentation/utilities/value_listenable_builder4.dart';

void main() {
  testWidgets('ValueListenableBuilder4 rebuilds when any listenable changes', (WidgetTester tester) async {
    final v1 = ValueNotifier<int>(1);
    final v2 = ValueNotifier<int>(2);
    final v3 = ValueNotifier<int>(3);
    final v4 = ValueNotifier<int>(4);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder4<int, int, int, int>(
          first: v1,
          second: v2,
          third: v3,
          fourth: v4,
          builder: (context, a, b, c, d, child) {
            return Text('$a-$b-$c-$d');
          },
        ),
      ),
    );

    // Initial render check
    expect(find.text('1-2-3-4'), findsOneWidget);

    // Update first notifier
    v1.value = 10;
    await tester.pump();
    expect(find.text('10-2-3-4'), findsOneWidget);

    // Update second notifier
    v2.value = 20;
    await tester.pump();
    expect(find.text('10-20-3-4'), findsOneWidget);

    // Update third notifier
    v3.value = 30;
    await tester.pump();
    expect(find.text('10-20-30-4'), findsOneWidget);

    // Update fourth notifier
    v4.value = 40;
    await tester.pump();
    expect(find.text('10-20-30-40'), findsOneWidget);
  });
}
