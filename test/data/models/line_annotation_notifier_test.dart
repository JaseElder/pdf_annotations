import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/line_annotation_notifier.dart';
import 'package:pdf_annotations/src/domain/entities/line_annotation.dart';

void main() {
  group('LineAnnotationNotifier', () {
    late LineAnnotationNotifier notifier;
    late LineAnnotation initialAnnotation;

    setUp(() {
      initialAnnotation = LineAnnotation([], Colors.black, 1.0);
      notifier = LineAnnotationNotifier(initialAnnotation);
    });

    test('should add a point to the line', () {
      const point = Offset(10, 20);
      notifier.addPoint(point);
      expect(notifier.value.line, [point]);
    });

    test('should set the current annotation', () {
      final newAnnotation = LineAnnotation([const Offset(5, 5)], Colors.red, 2.0);
      notifier.setCurrent(newAnnotation);
      expect(notifier.value, newAnnotation);
    });
  });
}
