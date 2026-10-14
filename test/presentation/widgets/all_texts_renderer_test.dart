import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/plugin_state.dart';
import 'package:pdf_annotations/src/domain/entities/text_annotation.dart';
import 'package:pdf_annotations/src/presentation/utilities/text_renderer.dart';
import 'package:pdf_annotations/src/presentation/widgets/all_texts_renderer.dart';
import 'package:pdf_annotations/src/utilities/constants.dart';

void main() {
  group('AllTextsRenderer', () {
    late PluginState state;

    setUp(() {
      state = PluginState(
        savedAnnotationsJsonSuffix: 'test',
        initialOffset: Offset.zero,
        initialAnnotationColour: Colors.red,
        draggingTextFieldBackgroundColour: Colors.blue,
        initialFontSize: 14.0,
        initialFontFamily: 'Arial',
      );
    });

    tearDown(() {
      state.dispose();
    });

    testWidgets('renders CustomPaint when annotations stream has data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginStateProvider(
              state,
              child: const AllTextsRenderer(),
            ),
          ),
        ),
      );

      final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is TextRenderer,
      );
      expect(customPaintFinder, findsNothing);

      final text = TextAnnotation('Hello', 'Arial', 14.0, 14.0, Offset.zero, Colors.black);
      state.updateTextsStream([text]);

      await tester.pumpAndSettle();

      expect(customPaintFinder, findsOneWidget);
    });

    testWidgets('triggers fade animation on undo action and clears notifier', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginStateProvider(
              state,
              child: const AllTextsRenderer(),
            ),
          ),
        ),
      );

      final text = TextAnnotation('Hello', 'Arial', 14.0, 14.0, Offset.zero, Colors.black);
      state.updateTextsStream([text]);
      await tester.pumpAndSettle();

      await tester.pump();

      state.lastUndoNotifier.value = (id: text.id, type: kTextAnnotation);

      // Let the animation play out completely
      await tester.pumpAndSettle();

      // The animation listener should have cleared the notifier back to empty strings!
      expect(state.lastUndoNotifier.value.id, isEmpty);
      expect(state.lastUndoNotifier.value.type, isEmpty);
    });

    testWidgets('triggers fade animation on redo action and clears notifier', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginStateProvider(
              state,
              child: const AllTextsRenderer(),
            ),
          ),
        ),
      );

      final text = TextAnnotation('Hello', 'Arial', 14.0, 14.0, Offset.zero, Colors.black);
      state.updateTextsStream([text]);
      await tester.pumpAndSettle();

      await tester.pump();

      state.lastRedoNotifier.value = (id: text.id, type: kTextAnnotation);

      // Let the animation play out completely
      await tester.pumpAndSettle();

      // The animation listener should have cleared the notifier back to empty strings!
      expect(state.lastRedoNotifier.value.id, isEmpty);
      expect(state.lastRedoNotifier.value.type, isEmpty);
    });
  });
}
