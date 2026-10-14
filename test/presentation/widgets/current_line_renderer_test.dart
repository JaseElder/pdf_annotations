import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/plugin_state.dart';
import 'package:pdf_annotations/src/domain/entities/line_annotation.dart';
import 'package:pdf_annotations/src/presentation/utilities/drawing_renderer.dart';
import 'package:pdf_annotations/src/presentation/widgets/current_line_renderer.dart';

void main() {
  testWidgets('CurrentLineRenderer builds and updates via stream', (WidgetTester tester) async {
    // Create an instance of the required PluginState
    final state = PluginState(
      savedAnnotationsJsonSuffix: 'test',
      initialOffset: Offset.zero,
      initialAnnotationColour: Colors.red,
      draggingTextFieldBackgroundColour: Colors.blue,
      initialFontSize: 14.0,
      initialFontFamily: 'Arial',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PluginStateProvider(
            state,
            child: const CurrentLineRenderer(),
          ),
        ),
      ),
    );

    // Initial check - stream has no data yet, should return an empty Container.
    // We check that our specific painter is NOT present yet.
    final customPaintFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is DrawingRenderer,
    );
    expect(customPaintFinder, findsNothing);

    // Push a new line annotation into the stream
    final newLine = LineAnnotation([Offset(0, 0), Offset(10, 10)], Colors.blue, 2.0);
    state.updateCurrentLineStream(newLine);

    // Pump a frame to let StreamBuilder react
    await tester.pumpAndSettle();

    // Verify our specific CustomPaint (with DrawingRenderer) is now rendered
    expect(customPaintFinder, findsOneWidget);

    // Clean up
    state.dispose();
  });
}
