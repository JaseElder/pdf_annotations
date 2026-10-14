import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/domain/entities/text_annotation.dart';
import 'package:pdf_annotations/src/presentation/utilities/text_renderer.dart';
import 'package:pdf_annotations/src/utilities/constants.dart';

void main() {
  group('TextRenderer', () {
    late TextAnnotation activeText;
    late TextAnnotation inactiveText;

    setUp(() {
      activeText = TextAnnotation(
        'Active Text',
        'Roboto',
        14.0,
        14.0,
        const Offset(10, 10),
        Colors.black,
        true,
        'txt-1',
      );

      inactiveText = TextAnnotation(
        'Inactive Text',
        'Arial',
        12.0,
        12.0,
        const Offset(50, 50),
        Colors.red,
        false,
        'txt-2',
      );
    });

    test('shouldRepaint evaluates equality correctly', () {
      final textList = [activeText];

      final renderer1 = TextRenderer(
        textAnnotations: textList,
        opacity: 1.0,
        latestUndo: (id: '', type: ''),
        latestRedo: (id: '', type: ''),
      );

      final rendererSame = TextRenderer(
        textAnnotations: textList,
        opacity: 1.0,
        latestUndo: (id: '', type: ''),
        latestRedo: (id: '', type: ''),
      );

      final rendererDiffOpacity = TextRenderer(
        textAnnotations: textList,
        opacity: 0.8,
        latestUndo: (id: '', type: ''),
        latestRedo: (id: '', type: ''),
      );

      final rendererDiffList = TextRenderer(
        textAnnotations: [activeText, inactiveText],
        opacity: 1.0,
        latestUndo: (id: '', type: ''),
        latestRedo: (id: '', type: ''),
      );

      expect(renderer1.shouldRepaint(rendererSame), isFalse);
      expect(renderer1.shouldRepaint(rendererDiffOpacity), isTrue);
      expect(renderer1.shouldRepaint(rendererDiffList), isTrue);
    });

    test('paint handles null entries, active, undo, and redo text annotations', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      final renderer = TextRenderer(
        textAnnotations: [null, activeText, inactiveText],
        opacity: 0.4,
        latestUndo: (id: 'txt-2', type: kTextAnnotation),
        latestRedo: (id: 'txt-1', type: kTextAnnotation),
      );

      renderer.paint(canvas, const Size(300, 300));

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
