import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/utilities/id_generator.dart';

void main() {
  group('IdGenerator', () {
    test('generates an id of the default length (4)', () {
      final id = generateId();
      expect(id.length, 4);
    });

    test('generates an id of a specific length', () {
      final id = generateId(10);
      expect(id.length, 10);
    });

    test('generates unique ids', () {
      final id1 = generateId(8);
      final id2 = generateId(8);
      expect(id1, isNot(equals(id2)));
    });

    test('generates alphanumeric ids', () {
      final id = generateId(100);
      final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
      expect(alphanumericRegex.hasMatch(id), isTrue);
    });
  });
}
