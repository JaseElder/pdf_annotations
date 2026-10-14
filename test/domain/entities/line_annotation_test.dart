import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/domain/entities/line_annotation.dart';

void main() {
  group('LineAnnotation', () {
    test('constructor initializes fields and generates id if not provided', () {
      final annotation = LineAnnotation(
        [const Offset(10, 10), const Offset(20, 20)],
        Colors.red,
        2.0,
      );

      expect(annotation.line, [const Offset(10, 10), const Offset(20, 20)]);
      expect(annotation.colour, Colors.red);
      expect(annotation.width, 2.0);
      expect(annotation.isActive, isTrue);
      expect(annotation.id, isNotEmpty);
      expect(annotation.primaryCoordinate, const Offset(10, 10));
    });

    test('copyWith produces modified copy with updated parameters', () {
      final original = LineAnnotation(
        [const Offset(0, 0), const Offset(10, 10)],
        Colors.black,
        1.0,
        true,
        'custom-id',
      );

      final updated = original.copyWith(
        width: 4.0,
        colour: Colors.blue,
        isActive: false,
      );

      expect(updated.id, 'custom-id');
      expect(updated.line, original.line);
      expect(updated.colour, Colors.blue);
      expect(updated.width, 4.0);
      expect(updated.isActive, isFalse);
    });

    test('toJson and fromJson cycle correctly', () {
      final annotation = LineAnnotation(
        [const Offset(15.5, 20.0), const Offset(30.0, 40.5)],
        const Color(0xFF12345678),
        3.5,
        true,
        'line-json-1',
      );

      final json = annotation.toJson();
      expect(json['id'], 'line-json-1');
      expect(json['line'], [
        [15.5, 20.0],
        [30.0, 40.5],
      ]);
      expect(json['colour'], const Color(0xFF12345678).toARGB32());
      expect(json['width'], 3.5);
      expect(json['is_active'], isTrue);

      final deserialized = LineAnnotation.fromJson(json);
      expect(deserialized, equals(annotation));
    });

    test('toJsonWithTransform subtracts transform offset from line points', () {
      final annotation = LineAnnotation(
        [const Offset(100, 200), const Offset(150, 250)],
        Colors.red,
        2.0,
        true,
        'trans-id',
      );

      final jsonTransformed = annotation.toJsonWithTransform(const Offset(10, 20));
      expect(jsonTransformed['line'], [
        [90.0, 180.0],
        [140.0, 230.0],
      ]);
    });

    test('toString returns formatted string representation', () {
      final annotation = LineAnnotation(
        [const Offset(0, 0)],
        Colors.red,
        1.0,
        true,
        'id-str',
      );

      expect(
        annotation.toString(),
        contains('LineAnnotation{id: id-str'),
      );
    });
  });
}
