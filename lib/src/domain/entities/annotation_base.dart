import 'dart:ui';

abstract class AnnotationBase {
  String get id;

  bool get isActive;

  Offset get primaryCoordinate;
}

typedef AnnotationCopier<T extends AnnotationBase> = T Function(T original, {bool? isActive});
