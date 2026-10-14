import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/plugin_state.dart';
import 'package:pdf_annotations/src/domain/entities/line_annotation.dart';
import 'package:pdf_annotations/src/presentation/utilities/drawing_renderer.dart';
import 'package:pdf_annotations/src/presentation/widgets/all_lines_renderer.dart';
import 'package:pdf_annotations/src/utilities/constants.dart';

void main() {
  group('AllLinesRenderer', () {
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
              child: const AllLinesRenderer(),
            ),
          ),
        ),
      );

      final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is DrawingRenderer,
      );
      expect(customPaintFinder, findsNothing);

      final line = LineAnnotation([Offset.zero, const Offset(10, 10)], Colors.black, 2.0);
      state.updateLinesStream([line]);

      await tester.pumpAndSettle();

      expect(customPaintFinder, findsOneWidget);
    });

    testWidgets('triggers fade animation on undo action', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginStateProvider(
              state,
              child: const AllLinesRenderer(),
            ),
          ),
        ),
      );

      final line = LineAnnotation([Offset.zero, const Offset(10, 10)], Colors.black, 2.0);
      state.updateLinesStream([line]);
      await tester.pumpAndSettle();

      // Wait for PostFrameCallback
      await tester.pump();

      state.lastUndoNotifier.value = (id: line.id, type: kLineAnnotation);

      await tester.pumpAndSettle();

      expect(state.lastUndoNotifier.value.id, isEmpty);
      expect(state.lastUndoNotifier.value.type, isEmpty);
    });

    testWidgets('triggers fade animation on redo action', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginStateProvider(
              state,
              child: const AllLinesRenderer(),
            ),
          ),
        ),
      );

      final line = LineAnnotation([Offset.zero, const Offset(10, 10)], Colors.black, 2.0);
      state.updateLinesStream([line]);
      await tester.pumpAndSettle();

      // Wait for PostFrameCallback
      await tester.pump();

      state.lastRedoNotifier.value = (id: line.id, type: kLineAnnotation);

      await tester.pumpAndSettle();
      expect(state.lastRedoNotifier.value.id, isEmpty);
      expect(state.lastRedoNotifier.value.type, isEmpty);
    });
  });
}
