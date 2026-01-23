import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:pdf_annotations/generated/pdf_annotations_api.dart';

import '../../domain/entities/line_annotation.dart';
import '../../domain/entities/text_annotation.dart';
import '../../domain/repositories/pdf_annotations_repository.dart';
import '../models/pdf_font.dart';

class PdfAnnotationsRepositoryImpl implements PdfAnnotationsRepository {
  static final PdfAnnotationsRepositoryImpl _instance = PdfAnnotationsRepositoryImpl._internal();

  factory PdfAnnotationsRepositoryImpl() {
    return _instance;
  }

  PdfAnnotationsRepositoryImpl._internal();

  final _annotationsApi = PdfAnnotationsApi();

  @override
  Future<bool> addAnnotations({
    required String fileName,
    required List<LineAnnotation> lineAnnotations,
    required List<TextAnnotation> textAnnotations,
    required List<PdfFont> fonts,
    required Offset pdfPageDims,
    required double totalPdfLength,
    required Offset viewportOffset,
    required double overlayScale,
  }) async {
    final translationResults = [
      lineAnnotations
          .where((lineAnnotation) => lineAnnotation.isActive)
          .map(
            (lineAnnotation) => _addTranslatedDrawingAnnotation(
              lineAnnotation,
              viewportOffset,
              overlayScale,
              totalPdfLength,
            ),
          )
          .toList(),
      textAnnotations
          .where((textAnnotation) => textAnnotation.isActive)
          .map(
            (textAnnotation) => _addTranslatedTextAnnotation(
              textAnnotation,
              fonts.firstWhere((font) => font.family == textAnnotation.fontFamily).fileName,
              viewportOffset,
              overlayScale,
              totalPdfLength,
            ),
          )
          .toList(),
    ];

    final annotationData = AnnotationData(
      fileName: fileName,
      drawingPaths: translationResults[0],
      textAnnotations: translationResults[1],
      pdfPageWidth: pdfPageDims.dx,
      pdfPageHeight: pdfPageDims.dy,
    );
    try {
      return await _annotationsApi.addAnnotations(annotationData);
    } on PlatformException {
      rethrow;
    }
  }

  Map<String, Object> _addTranslatedDrawingAnnotation(
    LineAnnotation annotation,
    Offset vpOffset,
    double overlayToPdfScale,
    double totalPdfLength,
  ) {
    // TODO do we really need this conversion? Does it look any better really?
    final extractedLine =
        annotation.line; //_extractPointsFromPath(_createPathFromLine(annotation.line));
    List<List<double>> translatedPath = extractedLine
        .map(
          (offset) => [
            vpOffset.dx + offset.dx * overlayToPdfScale,
            totalPdfLength - (vpOffset.dy + offset.dy * overlayToPdfScale),
          ],
        )
        .toList();
    return {
      'path': translatedPath,
      'colour': _colorToList(annotation.colour),
      'width': annotation.width * overlayToPdfScale,
    };
  }

  Path _createPathFromLine(List<Offset> line) {
    var realPath = Path();
    realPath.moveTo(line.first.dx, line.first.dy);

    for (int i = 1; i < line.length - 1; ++i) {
      var p0 = line[i];
      var p1 = line[i + 1];
      realPath.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    }

    return realPath;
  }

  List<Offset> _extractPointsFromPath(Path path, {double precision = 1.0}) {
    return path
        .computeMetrics()
        .expand((metric) => _pointsFromMetric(metric, precision: precision))
        .toList();
  }

  Iterable<Offset> _pointsFromMetric(PathMetric metric, {double precision = 1.0}) sync* {
    final double totalLength = metric.length;
    final double step = 1 / precision;

    for (double distance = 0.0; distance <= totalLength; distance += step) {
      yield metric.getTangentForOffset(distance)?.position ?? Offset.zero;
    }
  }

  List<int> _colorToList(Color color) {
    return [
      (color.a * 255).toInt(),
      (color.r * 255).toInt(),
      (color.g * 255).toInt(),
      (color.b * 255).toInt(),
    ];
  }

  Map<String, Object> _addTranslatedTextAnnotation(
    TextAnnotation textAnnotation,
    String fontFileName,
    Offset vpOffset,
    double overlayToPdfScale,
    double totalPdfLength,
  ) {
    List<double> translatedCoordinate = [
      vpOffset.dx + textAnnotation.coordinate.dx * overlayToPdfScale,
      totalPdfLength - (vpOffset.dy + textAnnotation.coordinate.dy * overlayToPdfScale),
    ];

    return {
      'text_string': textAnnotation.text,
      'font_name': fontFileName,
      'font_size': textAnnotation.pdfFontSize * overlayToPdfScale,
      'coordinate': translatedCoordinate,
      'colour': [
        (textAnnotation.colour.a * 255).toInt(),
        (textAnnotation.colour.r * 255).toInt(),
        (textAnnotation.colour.g * 255).toInt(),
        (textAnnotation.colour.b * 255).toInt(),
      ],
    };
  }

  @override
  Future<bool> undoAnnotation(String fileName, int pageNo) {
    try {
      return _annotationsApi.undoAnnotation(fileName, pageNo);
    } on PlatformException {
      rethrow;
    }
  }

  @override
  Future<bool> registerFonts(List<PdfFont> fontList) async {
    final fontNames = fontList.map((font) => font.fileName).toList();
    // needed in iOS
    return await _annotationsApi.registerFonts(fontNames);
  }
}
