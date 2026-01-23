import 'dart:ui';

import 'package:pdf_annotations/src/data/models/pdf_font.dart';
import 'package:pdf_annotations/src/domain/entities/line_annotation.dart';
import 'package:pdf_annotations/src/domain/entities/text_annotation.dart';

abstract class PdfAnnotationsRepository {
  Future<bool> addAnnotations({
    required String fileName,
    required List<LineAnnotation> lineAnnotations,
    required List<TextAnnotation> textAnnotations,
    required List<PdfFont> fonts,
    required Offset pdfPageDims,
    required double totalPdfLength,
    required Offset viewportOffset,
    required double overlayScale,
  });

  Future<bool> undoAnnotation(String fileName, int pageNo);

  Future<bool> registerFonts(List<PdfFont> fontList);
}
