import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/domain/entities/added_annotation.dart';

void main() {
  group('AddedAnnotation', () {
    test('constructor sets properties correctly with defaults', () {
      final annotation = AddedAnnotation('LineAnnotation', 'id-123');

      expect(annotation.annotationType, 'LineAnnotation');
      expect(annotation.id, 'id-123');
      expect(annotation.isActive, isTrue);
    });

    test('constructor sets explicit isActive value', () {
      final annotation = AddedAnnotation('TextAnnotation', 'id-456', false);

      expect(annotation.annotationType, 'TextAnnotation');
      expect(annotation.id, 'id-456');
      expect(annotation.isActive, isFalse);
    });

    test('toJson serializes correctly', () {
      final annotation = AddedAnnotation('TextAnnotation', 'id-789', true);
      final json = annotation.toJson();

      expect(json, {
        'annotation_type': 'TextAnnotation',
        'id': 'id-789',
        'is_active': true,
      });
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'annotation_type': 'LineAnnotation',
        'id': 'id-abc',
        'is_active': false,
      };

      final annotation = AddedAnnotation.fromJson(json);

      expect(annotation.annotationType, 'LineAnnotation');
      expect(annotation.id, 'id-abc');
      expect(annotation.isActive, isFalse);
    });

    test('toString returns expected string representation', () {
      final annotation = AddedAnnotation('TextAnnotation', 'id-999', true);

      expect(
        annotation.toString(),
        'AddedAnnotation{annotationType: TextAnnotation, id: id-999 isActive: true}',
      );
    });
  });
}
