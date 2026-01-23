import 'dart:ui';

import 'package:flutter/foundation.dart';
import '../../domain/entities/line_annotation.dart';

class LineAnnotationNotifier extends ValueNotifier<LineAnnotation> {
  LineAnnotationNotifier(super.value);

  void addPoint(Offset point) {
    final currentLineAnnotation = value;
    var newLine = List<Offset>.from(currentLineAnnotation.line)..add(point);
    value = currentLineAnnotation.copyWith(line: newLine);
  }

  void setCurrent(LineAnnotation annotation) {
    if (value != annotation) {
      value = annotation;
    }
  }
}
