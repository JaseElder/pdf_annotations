import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../domain/entities/annotation_base.dart';

class GenericAnnotationsNotifier<T extends AnnotationBase> extends ValueNotifier<List<T>> {
  final AnnotationCopier<T> _copier;

  GenericAnnotationsNotifier(this._copier) : super([]);

  void addAnnotation(T annotation) {
    if (value.any((element) => element.id == annotation.id)) {
      return;
    }
    value = [...value, annotation];
  }

  void addAnnotations(List<T> annotations) {
    value = [...value, ...annotations];
  }

  void setAnnotations(List<T> annotations) {
    if (value != annotations) {
      value = annotations;
    }
  }

  void removeLast() {
    if (value.isNotEmpty) {
      value = [...value]..removeLast();
    }
  }

  void removeInactiveAnnotations() {
    value = value.where((annotation) => annotation.isActive).toList();
  }

  bool areAllAnnotationsInactive() {
    return value.every((annotation) => !annotation.isActive);
  }

  Offset? inactivateId(String id) {
    int lastActiveIndex = value.indexWhere((annotation) => annotation.id == id);
    if (lastActiveIndex != -1) {
      final updatedAnnotation = _copier(value[lastActiveIndex], isActive: false);
      List<T> newValue = List.from(value);
      newValue[lastActiveIndex] = updatedAnnotation;

      value = newValue;

      return updatedAnnotation.primaryCoordinate;
    }
    return null;
  }

  Offset? activateId(String id) {
    int firstInactiveIndex = value.indexWhere((annotation) => annotation.id == id);

    if (firstInactiveIndex != -1) {
      final updatedAnnotation = _copier(value[firstInactiveIndex], isActive: true);
      List<T> newValue = List.from(value);
      newValue[firstInactiveIndex] = updatedAnnotation;

      value = newValue;

      return updatedAnnotation.primaryCoordinate;
    }
    return null;
  }
}
