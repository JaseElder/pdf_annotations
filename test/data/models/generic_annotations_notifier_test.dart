import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/generic_annotations_notifier.dart';
import 'package:pdf_annotations/src/domain/entities/text_annotation.dart';

void main() {
  group('GenericAnnotationsNotifier', () {
    late GenericAnnotationsNotifier<TextAnnotation> notifier;
    late TextAnnotation textAnnotation1;
    late TextAnnotation textAnnotation2;

    setUp(() {
      notifier = GenericAnnotationsNotifier<TextAnnotation>(
        (original, {bool? isActive}) => original.copyWith(isActive: isActive),
      );
      textAnnotation1 = TextAnnotation(
        'Annotation 1',
        'Roboto',
        12,
        12,
        const Offset(10, 10),
        Colors.black,
        true,
        '1',
      );
      textAnnotation2 = TextAnnotation(
        'Annotation 2',
        'Roboto',
        12,
        12,
        const Offset(20, 20),
        Colors.black,
        false,
        '2',
      );
      notifier.addAnnotations([textAnnotation1, textAnnotation2]);
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

    test('should add two annotations', () {
      final newAnnotation1 = TextAnnotation(
        'Annotation 3',
        'Roboto',
        12,
        12,
        const Offset(30, 30),
        Colors.black,
        true,
        '3',
      );
      final newAnnotation2 = TextAnnotation(
        'Annotation 4',
        'Roboto',
        10,
        9,
        const Offset(300, 300),
        Colors.orange,
        true,
        '4',
      );
      notifier.addAnnotations([newAnnotation1, newAnnotation2]);
      expect(notifier.value.length, 4);
      expect(notifier.value.last, newAnnotation2);
    });

    test('should set some annotations', () {
      notifier.setAnnotations([textAnnotation1, textAnnotation2]);
      expect(notifier.value.length, 2);
      expect(notifier.value.last, textAnnotation2);
    });

    test('should remove the last annotation', () {
      notifier.removeLast();
      expect(notifier.value.length, 1);
      expect(notifier.value.first, textAnnotation1);
    });

    test('should remove inactive annotations', () {
      notifier.removeInactiveAnnotations();
      expect(notifier.value.length, 1);
      expect(notifier.value.first, textAnnotation1);
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

    test('inactivateId should do nothing for a non-existent id', () {
      notifier.inactivateId('non-existent-id');
      // Verify that the list is unchanged
      expect(notifier.value.first.isActive, true);
      expect(notifier.value.length, 2);
    });

    test('activateId should do nothing for a non-existent id', () {
      notifier.activateId('non-existent-id');
      // Verify that the list is unchanged
      expect(notifier.value.last.isActive, false);
      expect(notifier.value.length, 2);
    });

    test('removeLast should not throw an error when the list is empty', () {
      // Create a new, empty notifier for this test
      final emptyNotifier = GenericAnnotationsNotifier<TextAnnotation>(
        (original, {bool? isActive}) => original.copyWith(isActive: isActive),
      );
      // This should complete without throwing an exception
      expect(() => emptyNotifier.removeLast(), returnsNormally);
    });

    test('areAllAnnotationsInactive should return true when the list is empty', () {
      final emptyNotifier = GenericAnnotationsNotifier<TextAnnotation>(
        (original, {bool? isActive}) => original.copyWith(isActive: isActive),
      );
      // Depending on your desired logic, this is often considered true
      expect(emptyNotifier.areAllAnnotationsInactive(), isTrue);
    });

    test('addAnnotation should not add an annotation if id already exists', () {
      final duplicateAnnotation = textAnnotation1.copyWith(text: 'new text');
      notifier.addAnnotation(duplicateAnnotation);

      expect(notifier.value.length, 2);
    });
  });
}
