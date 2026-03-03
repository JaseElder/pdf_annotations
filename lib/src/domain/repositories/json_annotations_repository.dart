import 'dart:ui';

import '../../utilities/enums.dart';
import '../entities/added_annotation.dart';
import '../entities/line_annotation.dart';
import '../entities/text_annotation.dart';

abstract class JsonAnnotationsRepository {
  /// Saves the current state of editable annotations.
  Future<SaveStateResult> saveAnnotationsState({
    required String pdfPath,
    required Offset vpPosition,
    required double overlayWidthScaled,
    required List<LineAnnotation> lineAnnotations,
    required List<TextAnnotation> textAnnotations,
    required List<AddedAnnotation> addedAnnotations,
    required QualityValue annotationQuality,
  });

  /// Loads the previously saved state of editable annotations.
  /// Returns a tuple with the loaded lists.
  Future<
    (
      List<LineAnnotation> lineAnnotations,
      List<TextAnnotation> textAnnotations,
      List<AddedAnnotation> addedAnnotations,
      QualityValue annotationQuality,
    )?
  >
  loadAnnotationsState({
    required String pdfPath,
    required Offset vpPosition,
    required double overlayWidthScaled,
    required double shortestSideEstimate,
  });
}
