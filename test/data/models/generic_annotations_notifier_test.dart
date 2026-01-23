import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/generic_annotations_notifier.dart';
import 'package:pdf_annotations/src/domain/entities/text_annotation.dart';

void main() {
  group('GenericAnnotationsNotifier', () {
    late GenericAnnotationsNotifier<TextAnnotation> notifier;
    late TextAnnotation annotation1;
    late TextAnnotation annotation2;

    setUp(() {
      notifier = GenericAnnotationsNotifier<TextAnnotation>(
        (original, {bool? isActive}) => original.copyWith(isActive: isActive),
      );
      annotation1 = TextAnnotation(
        'Annotation 1',
        'Roboto',
        12,
        12,
        const Offset(10, 10),
        Colors.black,
        true,
        '1',
      );
      annotation2 = TextAnnotation(
        'Annotation 2',
        'Roboto',
        12,
        12,
        const Offset(20, 20),
        Colors.black,
        false,
        '2',
      );
      notifier.addAnnotations([annotation1, annotation2]);
    });

    test('should add an annotation', () {
      final newAnnotation = TextAnnotation(
        'Annotation 3',
        'Roboto',
        12,
        12,
        const Offset(30, 30),
        Colors.black,
        true,
        '3',
      );
      notifier.addAnnotation(newAnnotation);
      expect(notifier.value.length, 3);
      expect(notifier.value.last, newAnnotation);
    });

    test('should remove the last annotation', () {
      notifier.removeLast();
      expect(notifier.value.length, 1);
      expect(notifier.value.first, annotation1);
    });

    test('should remove inactive annotations', () {
      notifier.removeInactiveAnnotations();
      expect(notifier.value.length, 1);
      expect(notifier.value.first, annotation1);
    });

    test('should inactivate an annotation by id', () {
      notifier.inactivateId('1');
      expect(notifier.value.first.isActive, false);
    });

    test('should activate an annotation by id', () {
      notifier.activateId('2');
      expect(notifier.value.last.isActive, true);
    });

    test('should check if all annotations are inactive', () {
      notifier.inactivateId('1');
      expect(notifier.areAllAnnotationsInactive(), true);
    });
  });
}
