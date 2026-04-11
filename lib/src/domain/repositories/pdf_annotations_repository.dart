import 'package:flutter/widgets.dart';

import '../../data/models/pdf_font.dart';
import '../../utilities/enums.dart';
import '../../utilities/errors.dart';
import '../entities/line_annotation.dart';
import '../entities/text_annotation.dart';

abstract class PdfAnnotationsRepository {
  Future<TaskResult<bool>> addAnnotations({
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

  Future<TaskResult<bool>> undoAnnotation(String fileName, int pageNo);

  Future<TaskResult<bool>> registerFonts(List<PdfFont> fontList);
}
