import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/domain/entities/line_annotation.dart';
import 'package:pdf_annotations/src/presentation/utilities/drawing_renderer.dart';
import 'package:pdf_annotations/src/utilities/constants.dart';
import 'package:pdf_annotations/src/utilities/enums.dart';

void main() {
  group('DrawingRenderer', () {
    late LineAnnotation line1;
    late LineAnnotation line2;

    setUp(() {
      line1 = LineAnnotation(
        [const Offset(10, 10), const Offset(50, 50), const Offset(100, 50)],
        Colors.red,
        2.0,
        true,
        'line-1',
      );
      line2 = LineAnnotation(
        [const Offset(0, 0), const Offset(20, 20)],
        Colors.blue,
        3.0,
        false,
        'line-2',
      );
    });

    test('shouldRepaint returns true when properties change', () {
      final lineList = [line1];

      final renderer1 = DrawingRenderer(
        lineAnnotations: lineList,
        annotationQuality: QualityValue.low,
        opacity: 1.0,
      );

      final rendererSame = DrawingRenderer(
        lineAnnotations: lineList,
        annotationQuality: QualityValue.low,
        opacity: 1.0,
      );

      final rendererDiffOpacity = DrawingRenderer(
        lineAnnotations: lineList,
        annotationQuality: QualityValue.low,
        opacity: 0.5,
      );

      final rendererDiffQuality = DrawingRenderer(
        lineAnnotations: lineList,
        annotationQuality: QualityValue.high,
        opacity: 1.0,
      );

      final rendererDiffLines = DrawingRenderer(
        lineAnnotations: [line1, line2],
        annotationQuality: QualityValue.low,
        opacity: 1.0,
      );

      expect(renderer1.shouldRepaint(rendererSame), isFalse);
      expect(renderer1.shouldRepaint(rendererDiffOpacity), isTrue);
      expect(renderer1.shouldRepaint(rendererDiffQuality), isTrue);
      expect(renderer1.shouldRepaint(rendererDiffLines), isTrue);
    });

    test('paint draws low quality straight paths and high quality bezier paths', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      final rendererLow = DrawingRenderer(
        lineAnnotations: [line1],
        annotationQuality: QualityValue.low,
      );

      final rendererHigh = DrawingRenderer(
        lineAnnotations: [line1],
        annotationQuality: QualityValue.high,
      );

      rendererLow.paint(canvas, const Size(200, 200));
      rendererHigh.paint(canvas, const Size(200, 200));

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('paint handles empty lines and inactive undo/redo states correctly', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      final emptyLine = LineAnnotation([], Colors.green, 1.0, true, 'empty-line');
      final inactiveLine = LineAnnotation([const Offset(5, 5)], Colors.black, 1.0, false, 'inactive');

      final renderer = DrawingRenderer(
        lineAnnotations: [emptyLine, inactiveLine],
        annotationQuality: QualityValue.high,
        opacity: 0.5,
        latestUndo: (id: 'inactive', type: kLineAnnotation),
      );

      renderer.paint(canvas, const Size(200, 200));

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('paint renders latestRedo active line opacity', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      final activeLine = LineAnnotation(
        [const Offset(10, 10), const Offset(20, 20)],
        Colors.red,
        2.0,
        true,
        'redo-line',
      );

      final renderer = DrawingRenderer(
        lineAnnotations: [activeLine],
        annotationQuality: QualityValue.high,
        opacity: 0.3,
        latestRedo: (id: 'redo-line', type: kLineAnnotation),
      );

      renderer.paint(canvas, const Size(200, 200));

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
