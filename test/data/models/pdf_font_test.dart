import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/pdf_font.dart';

void main() {
  group('PdfFont', () {
    test('should create a PdfFont object', () {
      final pdfFont = PdfFont(family: 'Arial', fileName: 'arial.ttf');
      expect(pdfFont.family, 'Arial');
      expect(pdfFont.fileName, 'arial.ttf');
    });
  });
}
