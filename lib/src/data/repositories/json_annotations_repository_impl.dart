import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/added_annotation.dart';
import '../../domain/entities/line_annotation.dart';
import '../../domain/entities/text_annotation.dart';
import '../../domain/repositories/json_annotations_repository.dart';

import '../../utilities/enums.dart';

class JsonAnnotationsRepositoryImpl implements JsonAnnotationsRepository {
  final String _savedAnnotationsJsonSuffix;

  JsonAnnotationsRepositoryImpl({required String savedAnnotationsJsonSuffix})
    : _savedAnnotationsJsonSuffix = savedAnnotationsJsonSuffix;

  @override
  Future<SaveStateResult> saveAnnotationsState({
    required List<LineAnnotation> lineAnnotations,
    required List<TextAnnotation> textAnnotations,
    required Offset vpPosition,
    required double overlayWidthScaled,
    required String pdfPath,
    required List<AddedAnnotation> addedAnnotations,
  }) async {
    bool noAnnotationIsActive =
        lineAnnotations.every((annotation) => !annotation.isActive) &&
        textAnnotations.every((annotation) => !annotation.isActive);

    if (noAnnotationIsActive) {
      return _deleteSavedAnnotationsFile(pdfPath);
    }

    final annotationMap = await _generateAnnotationMap(
      overlayWidthScaled: overlayWidthScaled,
      textAnnotations: textAnnotations,
      lineAnnotations: lineAnnotations,
      vpPosition: vpPosition,
      addedAnnotations: addedAnnotations,
    );

    try {
      final savedAnnotationsFile = await _getSavedAnnotationsFile(pdfPath);

      final bool fileExisted = await savedAnnotationsFile.exists();

      if (fileExisted) {
        bool contentsEqual = await _compareContents(savedAnnotationsFile, annotationMap);
        if (contentsEqual) {
          return .noChange;
        }
      }

      await savedAnnotationsFile.writeAsString(jsonEncode(annotationMap));

      return fileExisted ? .fileUpdated : .fileCreated;
    } catch (e) {
      return .error;
    }
  }

  Future<SaveStateResult> _deleteSavedAnnotationsFile(String pdfPath) async {
    try {
      final file = await _getSavedAnnotationsFile(pdfPath);
      if (await file.exists()) {
        await file.delete();
        return .fileDeleted;
      }
      return .noChange;
    } catch (e) {
      return .error;
    }
  }

  Future<File> _getSavedAnnotationsFile(String pdfPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final savedAnnotationsFileName =
        p.basenameWithoutExtension(pdfPath) + _savedAnnotationsJsonSuffix;
    return File('${dir.path}${Platform.pathSeparator}$savedAnnotationsFileName');
  }

  Future<Map<String, dynamic>> _generateAnnotationMap({
    required double overlayWidthScaled,
    required List<TextAnnotation> textAnnotations,
    required List<LineAnnotation> lineAnnotations,
    required Offset vpPosition,
    required List<AddedAnnotation> addedAnnotations,
  }) async {
    final orientation = await NativeDeviceOrientationCommunicator().orientation();
    return {
      'orientation': orientation.name.replaceAll(RegExp(r'Up|Down|Left|Right'), ''),
      'width': overlayWidthScaled,
      'texts': textAnnotations.map((t) => t.toJsonWithTransform(vpPosition)).toList(),
      'lines': lineAnnotations.map((l) => l.toJsonWithTransform(vpPosition)).toList(),
      'added': addedAnnotations.map((added) => added.toJson()).toList(),
    };
  }

  Future<bool> _compareContents(File file, Map<String, dynamic> newAnnotations) async {
    String fileContents = await file.readAsString();
    Map<String, dynamic> fileJson = json.decode(fileContents);
    final equality = const DeepCollectionEquality().equals;

    return equality(fileJson, newAnnotations);
  }

  @override
  Future<
    (
      List<LineAnnotation> lineAnnotations,
      List<TextAnnotation> textAnnotations,
      List<AddedAnnotation> addedAnnotations,
    )?
  >
  loadAnnotationsState({
    required double shortestSideEstimate,
    required String pdfPath,
    required double overlayWidthScaled,
    required Offset vpPosition,
  }) async {
    try {
      List<AddedAnnotation> addedAnnotations = [];

      final orientation = await NativeDeviceOrientationCommunicator().orientation();
      final savedAnnotationsFile = await _getSavedAnnotationsFile(pdfPath);
      if (await savedAnnotationsFile.exists()) {
        final annotations = await savedAnnotationsFile.readAsString();
        final decodedAnnotations = jsonDecode(annotations) as Map<String, dynamic>;

        final String orientationFromFile = decodedAnnotations['orientation'] ?? 'portrait';
        final double widthFromFile = decodedAnnotations['width'] ?? shortestSideEstimate;
        var scaleFactor = 1.0;
        if (!orientation.name.contains(orientationFromFile)) {
          scaleFactor = overlayWidthScaled / widthFromFile;
        }
        final lineAnnotations = _transformAnnotations<LineAnnotation>(
          decodedAnnotations['lines'],
          LineAnnotation.fromJson,
          (annotation) => annotation
            ..scaleLine(scaleFactor)
            ..transformLine(vpPosition),
        );

        final textAnnotations = _transformAnnotations<TextAnnotation>(
          decodedAnnotations['texts'],
          TextAnnotation.fromJson,
          (annotation) {
            annotation.coordinate =
                annotation.coordinate.scale(scaleFactor, scaleFactor) + vpPosition;
            annotation.renderedFontSize *= scaleFactor;
            annotation.pdfFontSize *= scaleFactor;
          },
        );
        addedAnnotations =
            decodedAnnotations['added']
                .map<AddedAnnotation>(
                  (json) => AddedAnnotation.fromJson(json as Map<String, dynamic>),
                )
                .toList() ??
            [];

        return (lineAnnotations, textAnnotations, addedAnnotations);
      }
    } catch (e) {
      // widget.onError?.call(e);
    }
    return null;
  }

  List<T> _transformAnnotations<T>(
    dynamic annotationsJson,
    T Function(Map<String, dynamic>) fromJson,
    void Function(T) applyTransform,
  ) {
    if (annotationsJson == null) return [];

    return (annotationsJson as List).map((json) {
      final annotation = fromJson(json);
      applyTransform(annotation);
      return annotation;
    }).toList();
  }
}
