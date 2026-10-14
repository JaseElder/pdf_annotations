import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/domain/entities/text_annotation.dart';

void main() {
  group('TextAnnotation', () {
    test('constructor initializes fields correctly', () {
      final annotation = TextAnnotation(
        'Sample Text',
        'Roboto',
        16.0,
        14.0,
        const Offset(50, 100),
        Colors.black,
        true,
        'text-id-1',
      );

      expect(annotation.id, 'text-id-1');
      expect(annotation.text, 'Sample Text');
      expect(annotation.fontFamily, 'Roboto');
      expect(annotation.pdfFontSize, 16.0);
      expect(annotation.renderedFontSize, 14.0);
      expect(annotation.coordinate, const Offset(50, 100));
      expect(annotation.originalCoordinate, const Offset(50, 100));
      expect(annotation.primaryCoordinate, const Offset(50, 100));
      expect(annotation.colour, Colors.black);
      expect(annotation.isActive, isTrue);
    });

    test('copyWith returns updated copy', () {
      final original = TextAnnotation(
        'Hello',
        'Arial',
        12.0,
        12.0,
        const Offset(10, 10),
        Colors.red,
        true,
        'text-id-2',
      );

      final copy = original.copyWith(
        text: 'World',
        colour: Colors.green,
        isActive: false,
      );

      expect(copy.id, 'text-id-2');
      expect(copy.text, 'World');
      expect(copy.fontFamily, 'Arial');
      expect(copy.colour, Colors.green);
      expect(copy.isActive, isFalse);
    });

    test('toJson and fromJson cycle correctly', () {
      final annotation = TextAnnotation(
        'Test JSON',
        'Helvetica',
        18.0,
        16.0,
        const Offset(25.0, 75.0),
        const Color(0xFF87654321),
        true,
        'json-id-3',
      );

      final json = annotation.toJson();
      expect(json['id'], 'json-id-3');
      expect(json['text'], 'Test JSON');
      expect(json['font_family'], 'Helvetica');
      expect(json['pdf_font_size'], 18.0);
      expect(json['rendered_font_size'], 16.0);
      expect(json['coordinate'], [25.0, 75.0]);
      expect(json['colour'], const Color(0xFF87654321).toARGB32());
      expect(json['is_active'], isTrue);

      final deserialized = TextAnnotation.fromJson(json);
      expect(deserialized, equals(annotation));
    });

    test('fromJson handles legacy font_name key as fallback', () {
      final legacyJson = {
        'id': 'legacy-id',
        'text': 'Legacy Text',
        'font_name': 'Courier',
        'pdf_font_size': 12.0,
        'rendered_font_size': 12.0,
        'coordinate': [10.0, 20.0],
        'colour': const Color(0xFF000000).toARGB32(),
        'is_active': true,
      };

      final annotation = TextAnnotation.fromJson(legacyJson);
      expect(annotation.fontFamily, 'Courier');
    });

    test('toJsonWithTransform subtracts offset from coordinate', () {
      final annotation = TextAnnotation(
        'Text',
        'Arial',
        12.0,
        12.0,
        const Offset(100, 200),
        Colors.blue,
        true,
        'trans-id',
      );

      final jsonTransformed = annotation.toJsonWithTransform(const Offset(20, 30));
      expect(jsonTransformed['coordinate'], [80.0, 170.0]);
    });

    test('toString includes key annotation details', () {
      final annotation = TextAnnotation(
        'Sample',
        'Roboto',
        12.0,
        12.0,
        Offset.zero,
        Colors.black,
        true,
        'str-id',
      );

      expect(annotation.toString(), contains('TextAnnotation{id: str-id, text: Sample'));
    });
  });
}
