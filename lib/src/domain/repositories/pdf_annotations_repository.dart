import 'package:flutter/widgets.dart';

import '../../data/models/pdf_font.dart';
import '../../utilities/enums.dart';
import '../entities/line_annotation.dart';
import '../entities/text_annotation.dart';

abstract class PdfAnnotationsRepository {
  Future<bool> addAnnotations({
    required String fileName,
    required List<LineAnnotation> lineAnnotations,
    required List<TextAnnotation> textAnnotations,
    required List<PdfFont> fonts,
    required QualityValue annotationQuality,
    required Offset pdfPageDims,
    required double totalPdfLength,
    required Offset viewportOffset,
    required double overlayScale,
  });

  Future<bool> undoAnnotation(String fileName, int pageNo);

  Future<bool> registerFonts(List<PdfFont> fontList);
}
