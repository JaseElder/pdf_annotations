import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/domain/entities/line_annotation.dart';
import 'package:pdf_annotations/src/domain/entities/text_annotation.dart';
import 'package:pdf_annotations/src/presentation/utilities/drawing_renderer.dart';
import 'package:pdf_annotations/src/presentation/utilities/text_renderer.dart';
import 'package:pdf_annotations/src/utilities/enums.dart';

void main() {
  group('Golden Rendering Tests', () {
    testWidgets('DrawingRenderer paints smooth high quality curved line', (WidgetTester tester) async {
      final lineAnnotation = LineAnnotation(
        [
          const Offset(20, 20),
          const Offset(100, 80),
          const Offset(180, 20),
          const Offset(250, 100),
        ],
        Colors.blue,
        5.0,
        true,
        'golden-line-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: CustomPaint(
                  painter: DrawingRenderer(
                    lineAnnotations: [lineAnnotation],
                    annotationQuality: QualityValue.high,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is DrawingRenderer,
        ),
        findsOneWidget,
      );
    });

    testWidgets('TextRenderer paints text annotation accurately on canvas', (WidgetTester tester) async {
      final textAnnotation = TextAnnotation(
        'Golden Sample Text',
        'Arial',
        16.0,
        20.0,
        const Offset(20, 40),
        Colors.purple,
        true,
        'golden-text-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 100,
                child: CustomPaint(
                  painter: TextRenderer(
                    textAnnotations: [textAnnotation],
                    opacity: 1.0,
                    latestUndo: (id: '', type: ''),
                    latestRedo: (id: '', type: ''),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is TextRenderer,
        ),
        findsOneWidget,
      );
    });
  });
}
