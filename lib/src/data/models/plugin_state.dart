import 'dart:async';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../domain/entities/added_annotation.dart';
import '../../domain/entities/line_annotation.dart';
import '../../domain/entities/text_annotation.dart';
import '../../domain/repositories/json_annotations_repository.dart';
import '../../utilities/enums.dart';
import '../repositories/json_annotations_repository_impl.dart';
import 'generic_annotations_notifier.dart';
import 'line_annotation_notifier.dart';
import 'text_insertion_point_notifier.dart';

class PluginState {
  late final JsonAnnotationsRepository _jsonAnnotationsRepository;

  final _textsStreamController = StreamController<List<TextAnnotation>>.broadcast();
  final _linesStreamController = StreamController<List<LineAnnotation>>.broadcast();
  final _currentLineStreamController = StreamController<LineAnnotation>.broadcast();

  Stream<List<TextAnnotation>> get textsStream => _textsStreamController.stream;

  Stream<List<LineAnnotation>> get linesStream => _linesStreamController.stream;

  Stream<LineAnnotation> get currentLineStream => _currentLineStreamController.stream;

  Size pdfPageSize = .zero;
  Color draggingTextFieldBackgroundColor = Colors.black;
  final LineAnnotation _defaultLineAnnotation = LineAnnotation([], Colors.transparent, 0.0);

  final popInvokedNotifier = ValueNotifier<bool>(false);
  final pdfOffsetNotifier = ValueNotifier<Offset>(.zero);
  final keyboardHeightNotifier = ValueNotifier<double>(0.0);
  final textFieldShowingNotifier = ValueNotifier<bool>(false);
  final annotationColourNotifier = ValueNotifier<Color>(Colors.transparent);
  final fontSizeNotifier = ValueNotifier<double>(16.0);
  final fontFamilyNotifier = ValueNotifier<String>('Roboto');
  final textFocusNodeNotifier = ValueNotifier<FocusNode>(FocusNode());
  final textInsertionPointNotifier = TextInsertionPointNotifier(.zero);
  final editModeNotifier = ValueNotifier<EditMode>(.pan);
  late final currentLineAnnotationNotifier = LineAnnotationNotifier(_defaultLineAnnotation);
  final lineModeNotifier = ValueNotifier<LineMode>(.pen);
  final cursorAdjustmentForKeyboardHeightNotifier = ValueNotifier<double>(0.0);
  final opacityValueNotifier = ValueNotifier<double>(1.0);
  final lastUndoNotifier = ValueNotifier<({String id, String type})>((id: '', type: ''));
  final annotationQualityNotifier = ValueNotifier<QualityValue>(.high);

  final lineAnnotationsListNotifier = GenericAnnotationsNotifier<LineAnnotation>(
    (original, {bool? isActive}) => original.copyWith(isActive: isActive),
  );
  final textAnnotationsListNotifier = GenericAnnotationsNotifier<TextAnnotation>(
    (original, {bool? isActive}) => original.copyWith(isActive: isActive),
  );

  final ValueNotifier<bool> undoEnabledNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> redoEnabledNotifier = ValueNotifier<bool>(false);

  EditMode get editMode => editModeNotifier.value;

  set editMode(EditMode mode) => editModeNotifier.value = mode;

  Offset get textInsertionPoint => textInsertionPointNotifier.value;

  FocusNode get textFocusNode => textFocusNodeNotifier.value;

  late final pdfViewController = ValueNotifier<PDFViewController?>(null);

  PluginState({
    required String savedAnnotationsJsonSuffix,
    required Offset initialOffset,
    required Color initialAnnotationColour,
    required Color draggingTextFieldBackgroundColour,
    required double initialFontSize,
    required String initialFontFamily,
  }) {
    _textsStreamController.add(textAnnotationsListNotifier.value);
    _linesStreamController.add(lineAnnotationsListNotifier.value);
    _currentLineStreamController.add(currentLineAnnotationNotifier.value);
    _jsonAnnotationsRepository = JsonAnnotationsRepositoryImpl(
      savedAnnotationsJsonSuffix: savedAnnotationsJsonSuffix,
    );
    pdfOffsetNotifier.value = initialOffset;
    annotationColourNotifier.value = initialAnnotationColour;
    draggingTextFieldBackgroundColor = draggingTextFieldBackgroundColour;
    fontSizeNotifier.value = initialFontSize;
    fontFamilyNotifier.value = initialFontFamily;
  }

  void dispose() {
    _textsStreamController.close();
    _linesStreamController.close();
    _currentLineStreamController.close();
  }

  void updateTextsStream(List<TextAnnotation> textAnnotations) {
    textAnnotationsListNotifier.value = textAnnotations;
    _textsStreamController.add(textAnnotations);
  }

  void updateLinesStream(List<LineAnnotation> lineAnnotations) {
    lineAnnotationsListNotifier.value = lineAnnotations;
    _linesStreamController.add(lineAnnotations);
  }

  void updateCurrentLineStream(LineAnnotation lineAnnotation) {
    currentLineAnnotationNotifier.value = lineAnnotation;
    _currentLineStreamController.add(currentLineAnnotationNotifier.value);
  }

  void resetCurrentLineAnnotationNotifier() {
    currentLineAnnotationNotifier.value = _defaultLineAnnotation;
  }

  void updateUndoRedoState() {
    final lineAnnotations = lineAnnotationsListNotifier.value;
    final textAnnotations = textAnnotationsListNotifier.value;

    bool hasActiveLineAnnotations = lineAnnotations.any((annotation) => annotation.isActive);
    bool hasActiveTextAnnotations = textAnnotations.any((annotation) => annotation.isActive);
    bool hasInactiveLineAnnotations = lineAnnotations.any((annotation) => !annotation.isActive);
    bool hasInactiveTextAnnotations = textAnnotations.any((annotation) => !annotation.isActive);

    final newUndoEnabled = hasActiveLineAnnotations || hasActiveTextAnnotations;
    final newRedoEnabled = hasInactiveLineAnnotations || hasInactiveTextAnnotations;

    if (undoEnabledNotifier.value != newUndoEnabled) {
      undoEnabledNotifier.value = newUndoEnabled;
    }
    if (redoEnabledNotifier.value != newRedoEnabled) {
      redoEnabledNotifier.value = newRedoEnabled;
    }
  }

  Future<SaveStateResult> saveAnnotationsToJson({
    required String pdfPath,
    required Offset viewportPosition,
    required double scaledOverlayWidth,
    required List<AddedAnnotation> addedAnnotations,
  }) {
    return _jsonAnnotationsRepository.saveAnnotationsState(
      lineAnnotations: lineAnnotationsListNotifier.value,
      textAnnotations: textAnnotationsListNotifier.value,
      addedAnnotations: addedAnnotations,
      vpPosition: viewportPosition,
      overlayWidthScaled: scaledOverlayWidth,
      pdfPath: pdfPath,
    );
  }

  Future<List<AddedAnnotation>> loadPreviousSavedJson({
    required String pdfPath,
    required Offset viewportPosition,
    required double scaledOverlayWidth,
    required double shortestSideEstimate,
  }) async {
    var loadedData = await _jsonAnnotationsRepository.loadAnnotationsState(
      pdfPath: pdfPath,
      vpPosition: viewportPosition,
      overlayWidthScaled: scaledOverlayWidth,
      shortestSideEstimate: shortestSideEstimate,
    );

    if (loadedData == null) {
      return [];
    }

    var (lineAnnotations, textAnnotations, addedAnnotations) = loadedData;

    if (lineAnnotations.isNotEmpty) {
      lineAnnotationsListNotifier.addAnnotations(lineAnnotations);
    }
    if (textAnnotations.isNotEmpty) {
      textAnnotationsListNotifier.addAnnotations(textAnnotations);
    }
    return addedAnnotations;
  }
}

class PluginStateProvider extends InheritedWidget {
  const PluginStateProvider(this.data, {super.key, required super.child});

  final PluginState data;

  static PluginState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PluginStateProvider>()!.data;
  }

  @override
  bool updateShouldNotify(PluginStateProvider oldWidget) {
    return data != oldWidget.data;
  }
}
