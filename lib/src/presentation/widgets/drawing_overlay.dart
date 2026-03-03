import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/plugin_state.dart';
import '../../domain/entities/added_annotation.dart';
import '../../domain/entities/line_annotation.dart';
import '../../domain/entities/text_annotation.dart';
import '../../utilities/constants.dart';
import '../../utilities/enums.dart';
import 'all_overlay_widgets.dart';
import 'current_line_renderer.dart';
import 'current_text.dart';
import 'pan_layer.dart';
import 'pdf_doc_view.dart';

typedef InsertionPointSelectedCallback = Future<void> Function(double keyboardHeight);

class DrawingOverlayController extends ChangeNotifier {
  _DrawingOverlayState? _state;

  Future<void> undo() async {
    await _state?._undoLast();
  }

  Future<void> redo() async {
    await _state?._redoLast();
  }

  Future<SaveStateResult> saveAnnotationsToJsonFile() async {
    return await _state?._saveProgress() ?? .error;
  }

  double getOverlayWidthScaled() {
    return _state?._overlayWidthScaled ?? 1.0;
  }

  void _attach(_DrawingOverlayState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }
}

class DrawingOverlay extends StatefulWidget {
  final DrawingOverlayController drawingOverlayController;
  final String pdfPath;

  /// Callback to inform owner about a change in text insertion point location when the insertion point
  /// would have been under the appearing keyboard
  final InsertionPointSelectedCallback onInsertionPointModified;
  final ErrorCallback? onError;

  const DrawingOverlay({
    super.key,
    required this.drawingOverlayController,
    required this.pdfPath,
    required this.onInsertionPointModified,
    this.onError,
  });

  @override
  State<DrawingOverlay> createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<DrawingOverlay> with SingleTickerProviderStateMixin {
  late PluginState _pluginState;
  final _textFieldController = TextEditingController();
  final _rawGDKey = UniqueKey();
  double _selectedLineWidth = 5.0;
  final double _currentScale = 1.0;
  List<LineAnnotation> _startOfPanningLines = [];
  List<TextAnnotation> _startOfPanningTexts = [];
  Offset _startOfTextEntryInsertionPoint = .zero;
  Offset _vpPositionAtStartOfPanning = .zero;
  Offset _vpPosition = .zero;
  late double _invPixRatio;
  late double _devPixRatio;
  List<AddedAnnotation> _addedAnnotations = [];
  late final AnimationController _animationController;
  late final CurvedAnimation _curvedAnimation;
  late Animation<double> _lineAnnotationsAnimation;
  late Function() _lineAnimationListener;
  late Animation<double> _textAnnotationsAnimation;
  late Function() _textAnimationListener;
  late Animation<double> _currentTextAnimation;
  late Function() _currentTextAnimationListener;
  late double _overlayWidthScaled;
  late double _overlayHeightScaled;
  bool _keyboardActive = false;
  TextAnnotation? _currentTextAnnotation;
  bool _didChangeDependenciesRun = false;
  late Color _annotationColour;

  late final CurrentText _currentText = CurrentText(
    textFieldController: _textFieldController,
    scale: _currentScale,
    onTapUp: _onTextTapUp,
    onTapOutside: _onTapOutside,
    onFirstCharacterEntry: _clearUndoList,
  );

  late final Widget _currentLine = Positioned.fill(
    child: GestureDetector(
      onDoubleTap: () {},
      onScaleStart: _onLineScaleStart,
      onScaleUpdate: _onLineScaleUpdate,
      onScaleEnd: _onLineScaleEnd,
      behavior: .opaque,
      child: const RepaintBoundary(child: CurrentLineRenderer()),
    ),
  );

  late final PanLayer _panLayer = PanLayer(gDKey: _rawGDKey, onDragStart: _onPanDragStart);

  @override
  void initState() {
    super.initState();
    widget.drawingOverlayController._attach(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: kAnnotationsAnimationDuration),
      vsync: this,
    );
    _curvedAnimation = CurvedAnimation(parent: _animationController, curve: Curves.decelerate);
    _currentTextAnimationListener = () {
      final deltaY = _currentTextAnimation.value;
      _pluginState.textInsertionPointNotifier.setAbsolute(
        _startOfTextEntryInsertionPoint + Offset(0.0, deltaY),
      );
    };
    _lineAnimationListener = () {
      final deltaY = _lineAnnotationsAnimation.value;
      _pluginState.lineAnnotationsListNotifier.setAnnotations(
        _startOfPanningLines
            .map(
              (annotation) => annotation.copyWith(
                line: annotation.line.map((offset) => offset.translate(0, deltaY)).toList(),
              ),
            )
            .toList(),
      );
    };
    _textAnimationListener = () {
      final deltaY = _textAnnotationsAnimation.value;
      _pluginState.textAnnotationsListNotifier.setAnnotations(
        _startOfPanningTexts
            .map(
              (annotation) =>
                  annotation.copyWith(coordinate: annotation.coordinate + Offset(0, deltaY)),
            )
            .toList(),
      );
    };
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _updateViewportPosition();
      await _loadPreviousSave();
      _pluginState.updateUndoRedoEnabledState();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pluginState = PluginStateProvider.of(context);
    _setAnnotationColour();
    _setLineWidth();

    if (_didChangeDependenciesRun) {
      return;
    }
    _didChangeDependenciesRun = true;
    _pluginState.pdfOffsetNotifier.addListener(_moveByPanning);
    _pluginState.keyboardHeightNotifier.addListener(_keyboardHeightUpdate);
    _pluginState.annotationColourNotifier.addListener(_setAnnotationColour);
    _pluginState.lineModeNotifier.addListener(_setLineWidth);
    _pluginState.textInsertionPointNotifier.addListener(_updateTextInsertionPoint);
    _pluginState.editModeNotifier.addListener(_setInitialMoveConditions);
    _pluginState.currentLineAnnotationNotifier.addListener(_updateCurrentLineStream);
    _pluginState.textAnnotationsListNotifier.addListener(_updateTextsStream);
    _pluginState.lineAnnotationsListNotifier.addListener(_updateLinesStream);
  }

  @override
  void didUpdateWidget(covariant DrawingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.drawingOverlayController != oldWidget.drawingOverlayController) {
      oldWidget.drawingOverlayController._detach();
      widget.drawingOverlayController._attach(this);
    }
  }

  @override
  void dispose() {
    _pluginState.pdfOffsetNotifier.removeListener(_moveByPanning);
    _pluginState.keyboardHeightNotifier.removeListener(_keyboardHeightUpdate);
    _pluginState.annotationColourNotifier.removeListener(_setAnnotationColour);
    _pluginState.lineModeNotifier.removeListener(_setLineWidth);
    _pluginState.textInsertionPointNotifier.removeListener(_updateTextInsertionPoint);
    _pluginState.editModeNotifier.removeListener(_setInitialMoveConditions);
    _pluginState.currentLineAnnotationNotifier.removeListener(_updateCurrentLineStream);
    _pluginState.textAnnotationsListNotifier.removeListener(_updateTextsStream);
    _pluginState.lineAnnotationsListNotifier.removeListener(_updateLinesStream);

    widget.drawingOverlayController._detach();
    _animationController.dispose();
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initializePixRatios();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _overlayHeightScaled = constraints.maxHeight * _devPixRatio;
        _overlayWidthScaled = constraints.maxWidth * _devPixRatio;
        return ValueListenableBuilder<EditMode>(
          valueListenable: _pluginState.editModeNotifier,
          builder: (context, currentEditMode, child) {
            return AllOverlayWidgets(
              currentText: _currentText,
              currentLine: _currentLine,
              panLayer: _panLayer,
              selectedEditMode: currentEditMode,
            );
          },
        );
      },
    );
  }

  void _initializePixRatios() {
    _devPixRatio = MediaQuery.devicePixelRatioOf(context);
    _invPixRatio = 1 / _devPixRatio;
  }

  void _updateViewportPosition() {
    _vpPosition = _vpPositionAtStartOfPanning = _pluginState.pdfOffsetNotifier.value * _invPixRatio;
  }

  void _moveByPanning() {
    if (!_keyboardActive) {
      _vpPosition = _pluginState.pdfOffsetNotifier.value * _invPixRatio;
      final delta = _vpPosition - _vpPositionAtStartOfPanning;
      _moveLineAnnotationsAbsolute(delta);
      _moveTextAnnotationsAbsolute(delta);
    }
  }

  Future<void> _keyboardHeightUpdate() async {
    if (!_pluginState.isPopInvoked) {
      await _handleKeyboardHeight(_pluginState.keyboardHeightNotifier.value);
    }
  }

  void _setAnnotationColour() {
    _annotationColour = _pluginState.annotationColour;
    if (_pluginState.editMode == .text && _currentTextAnnotation != null) {
      _currentTextAnnotation = _currentTextAnnotation?.copyWith(colour: _annotationColour);
    }
  }

  void _setLineWidth() {
    _selectedLineWidth = _pluginState.lineModeNotifier.value == .pen ? 5.0 : 15.0;
  }

  void _updateTextInsertionPoint() {
    if (_pluginState.editMode == .text && _currentTextAnnotation != null) {
      _currentTextAnnotation = _currentTextAnnotation?.copyWith(
        coordinate: _pluginState.textInsertionPoint,
      );
    }
  }

  void _setInitialMoveConditions() {
    _startOfPanningLines = _pluginState.lineAnnotationsListNotifier.value;
    _startOfPanningTexts = _pluginState.textAnnotationsListNotifier.value;
    _vpPositionAtStartOfPanning = _vpPosition;
  }

  void _updateCurrentLineStream() {
    _pluginState.updateCurrentLineStream(_pluginState.currentLineAnnotationNotifier.value);
  }

  void _updateLinesStream() {
    _pluginState.updateLinesStream(_pluginState.lineAnnotationsListNotifier.value);
    _pluginState.updateUndoRedoEnabledState();
  }

  void _updateTextsStream() {
    _pluginState.updateTextsStream(_pluginState.textAnnotationsListNotifier.value);
    _pluginState.updateUndoRedoEnabledState();
  }

  void _onLineScaleStart(ScaleStartDetails details) {
    if (details.pointerCount > 1) {
      return;
    }
    _clearUndoList();
    final annotationColor = (_pluginState.lineModeNotifier.value == .highlighter)
        ? _annotationColour.withValues(alpha: kHighlighterOpacity)
        : _annotationColour;

    _pluginState.currentLineAnnotationNotifier.setCurrent(
      LineAnnotation(
        [details.localFocalPoint],
        annotationColor,
        _selectedLineWidth * _currentScale,
      ),
    );
  }

  void _clearUndoList() {
    _pluginState.lineAnnotationsListNotifier.removeInactiveAnnotations();
    _pluginState.textAnnotationsListNotifier.removeInactiveAnnotations();
    _addedAnnotations.removeWhere((annotation) => !annotation.isActive);
  }

  void _onLineScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > 1) {
      return;
    }
    _pluginState.currentLineAnnotationNotifier.addPoint(details.localFocalPoint);
  }

  void _onLineScaleEnd(ScaleEndDetails details) {
    var currentAnnotation = _pluginState.currentLineAnnotationNotifier.value;
    _pluginState.resetCurrentLineAnnotationNotifier();
    if (currentAnnotation.line.isNotEmpty) {
      _pluginState.lineAnnotationsListNotifier.addAnnotation(currentAnnotation);
      _addedAnnotations.add(AddedAnnotation(kLineAnnotation, currentAnnotation.id));
      _setInitialMoveConditions();
    }
  }

  void _onTextTapUp(TapUpDetails details) {
    _finaliseTexting(fromTextEdit: true);
    _pluginState.textInsertionPointNotifier.setAbsolute(details.localPosition);
    _startOfTextEntryInsertionPoint = details.localPosition.translate(
      0.0,
      _pluginState.cursorAdjustmentForKeyboardHeightNotifier.value,
    );
    _pluginState.textFocusNode.requestFocus();
    _pluginState.textFieldShowingNotifier.value = true;
  }

  void _onTapOutside(String text) {
    if (text.trim().isNotEmpty) {
      _currentTextAnnotation = TextAnnotation(
        text.trim(),
        _pluginState.fontFamilyNotifier.value,
        MediaQuery.textScalerOf(context).scale(_pluginState.fontSizeNotifier.value),
        MediaQuery.textScalerOf(context).scale(_pluginState.fontSizeNotifier.value) * _currentScale,
        _pluginState.textInsertionPoint,
        _annotationColour,
      );
    }
  }

  Future<void> _handleKeyboardHeight(double newKbHeight) async {
    if (newKbHeight != 0.0) {
      // keyboard showing
      _keyboardActive = true;
      await _doAnnotationKBShift(newKbHeight);
    } else {
      _finaliseTexting(forKeyboardHide: true);
      await _undoAnnotationKBShift();
      _setInitialMoveConditions();
      _keyboardActive = false;
    }
  }

  Future<void> _doAnnotationKBShift(double newKbHeight) async {
    RenderBox rb = context.findRenderObject() as RenderBox;
    final visibleHeightAfterKbShow = rb.size.height - (newKbHeight + kKeyboardToolbarHeight);
    final currentInsertionPointYPos = _pluginState.textInsertionPoint.dy;
    if (currentInsertionPointYPos > visibleHeightAfterKbShow) {
      final deltaY = currentInsertionPointYPos - visibleHeightAfterKbShow;
      _pluginState.cursorAdjustmentForKeyboardHeightNotifier.value = deltaY;
      await Future.wait([
        // move text field up to account for keyboard show
        _animateCurrentTextForKbShift(0.0, -deltaY),
        // move all drawn lines and texts up to account for keyboard show
        _animateTextAnnotationsForKbShift(0.0, -deltaY),
        _animateLineAnnotationsForKbShift(0.0, -deltaY),
        // tell pdfview it needs to move up
        widget.onInsertionPointModified(deltaY),
      ]);
    }
  }

  Future<void> _undoAnnotationKBShift() async {
    final cursorAdjustment = _pluginState.cursorAdjustmentForKeyboardHeightNotifier.value;
    if (cursorAdjustment != 0.0) {
      if (!_pluginState.popInvokedNotifier.value) {
        _pluginState.cursorAdjustmentForKeyboardHeightNotifier.value = 0.0;
        await Future.wait([
          // reset text and line annotation positions
          _animateTextAnnotationsForKbShift(-cursorAdjustment, 0.0),
          _animateLineAnnotationsForKbShift(-cursorAdjustment, 0.0),
          // tell pdfview it needs to move down
          widget.onInsertionPointModified(-cursorAdjustment),
        ]);
      } else {
        _pluginState.textAnnotationsListNotifier.setAnnotations(_startOfPanningTexts);
        _pluginState.lineAnnotationsListNotifier.setAnnotations(_startOfPanningLines);
        widget.onInsertionPointModified(-cursorAdjustment);
      }
    }
  }

  void _onPanDragStart(DragStartDetails details) {
    _setInitialMoveConditions();
  }

  Future<void> _animateTextAnnotationsForKbShift(double begin, double end) {
    final Completer<void> completer = Completer<void>();
    if (_pluginState.textAnnotationsListNotifier.value.isNotEmpty) {
      if (begin == 0.0) {
        _startOfPanningTexts = _pluginState.textAnnotationsListNotifier.value;
      }
      _textAnnotationsAnimation = Tween<double>(begin: begin, end: end).animate(_curvedAnimation)
        ..addListener(_textAnimationListener);

      void statusListener(AnimationStatus status) {
        if (status == .completed) {
          _textAnnotationsAnimation.removeListener(_textAnimationListener);
          if (end == 0.0) {
            _startOfPanningTexts = [];
          }
          _textAnnotationsAnimation.removeStatusListener(statusListener);
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      }

      _textAnnotationsAnimation.addStatusListener(statusListener);

      _animationController.reset();
      _animationController.forward();
    } else {
      completer.complete();
    }
    return completer.future;
  }

  void _moveTextAnnotationsAbsolute(Offset absPoint) {
    if (_startOfPanningTexts.isNotEmpty) {
      final tempTexts = _startOfPanningTexts.map((annotation) {
        final newCoord = _currentScale == 1.0
            ? annotation.coordinate.translate(0, absPoint.dy)
            : annotation.coordinate + absPoint;
        return annotation.copyWith(coordinate: newCoord);
      }).toList();
      _pluginState.textAnnotationsListNotifier.setAnnotations(tempTexts);
    }
  }

  Future<void> _animateLineAnnotationsForKbShift(double begin, double end) {
    final Completer<void> completer = Completer<void>();
    if (_pluginState.lineAnnotationsListNotifier.value.isNotEmpty) {
      if (begin == 0.0) {
        _startOfPanningLines = _pluginState.lineAnnotationsListNotifier.value;
      }
      _lineAnnotationsAnimation = Tween<double>(begin: begin, end: end).animate(_curvedAnimation)
        ..addListener(_lineAnimationListener);

      void statusListener(AnimationStatus status) {
        if (status == .completed) {
          _lineAnnotationsAnimation.removeListener(_lineAnimationListener);
          if (end == 0.0) {
            _startOfPanningLines = [];
          }
          _lineAnnotationsAnimation.removeStatusListener(statusListener);
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      }

      _lineAnnotationsAnimation.addStatusListener(statusListener);

      _animationController.reset();
      _animationController.forward();
    } else {
      completer.complete();
    }
    return completer.future;
  }

  void _moveLineAnnotationsAbsolute(Offset absPoint) {
    if (_startOfPanningLines.isNotEmpty) {
      _pluginState.lineAnnotationsListNotifier.setAnnotations(
        _startOfPanningLines
            .map(
              (annotation) => annotation.copyWith(
                line: annotation.line.map((offset) => offset + absPoint).toList(),
              ),
            )
            .toList(),
      );
    }
  }

  Future<void> _animateCurrentTextForKbShift(double begin, double end) {
    final Completer<void> completer = Completer<void>();
    _currentTextAnimation = Tween<double>(begin: begin, end: end).animate(_curvedAnimation)
      ..addListener(_currentTextAnimationListener);

    void statusListener(AnimationStatus status) {
      if (status == .completed) {
        _currentTextAnimation.removeListener(_currentTextAnimationListener);
        _currentTextAnimation.removeStatusListener(statusListener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }

    _currentTextAnimation.addStatusListener(statusListener);

    _animationController.reset();
    _animationController.forward();

    return completer.future;
  }

  void _finaliseTexting({bool fromTextEdit = false, bool forKeyboardHide = false}) {
    if (!fromTextEdit) {
      // TODO would this help for nexus
      _pluginState.textFocusNode.unfocus();
    }
    if (_textFieldController.text.trim().isNotEmpty) {
      final currentTextAnnotation =
          _currentTextAnnotation?.copyWith(coordinate: _pluginState.textInsertionPoint) ??
          TextAnnotation(
            _textFieldController.text.trim(),
            _pluginState.fontFamilyNotifier.value,
            MediaQuery.textScalerOf(context).scale(_pluginState.fontSizeNotifier.value),
            MediaQuery.textScalerOf(context).scale(_pluginState.fontSizeNotifier.value) *
                _currentScale,
            _pluginState.textInsertionPoint,
            _annotationColour,
          );

      if (!_pluginState.textAnnotationsListNotifier.value.contains(currentTextAnnotation)) {
        _pluginState.textAnnotationsListNotifier.addAnnotation(currentTextAnnotation);
        _addedAnnotations.add(AddedAnnotation(kTextAnnotation, currentTextAnnotation.id));
        if (forKeyboardHide) {
          _startOfPanningTexts.add(
            currentTextAnnotation.copyWith(
              coordinate:
                  _pluginState.textInsertionPoint +
                  Offset(0.0, _pluginState.cursorAdjustmentForKeyboardHeightNotifier.value),
            ),
          );
        } else {
          _setInitialMoveConditions();
        }
      }
    }
    _currentTextAnnotation = null;
    _textFieldController.clear();
  }

  Future<void> _undoLast() async {
    _finaliseTexting(fromTextEdit: true);
    final lastActiveIndex = _addedAnnotations.lastIndexWhere((annotation) => annotation.isActive);
    if (lastActiveIndex != -1) {
      final lastActiveAnnotation = _addedAnnotations[lastActiveIndex];
      Offset? position;
      if (lastActiveAnnotation.annotationType == kTextAnnotation) {
        position = _pluginState.textAnnotationsListNotifier.inactivateId(lastActiveAnnotation.id);
      } else if (lastActiveAnnotation.annotationType == kLineAnnotation) {
        position = _pluginState.lineAnnotationsListNotifier.inactivateId(lastActiveAnnotation.id);
      }
      _pluginState.updateUndoRedoEnabledState();
      _pluginState.lastUndoNotifier.value = (
        id: lastActiveAnnotation.id,
        type: lastActiveAnnotation.annotationType,
      );
      lastActiveAnnotation.isActive = false;
      if (position != null && !_pluginState.textFocusNode.hasFocus) {
        _setInitialMoveConditions();
        await _setPdfOffset(position);
      }
    }
  }

  Future<void> _redoLast() async {
    _finaliseTexting(fromTextEdit: true);
    final firstInactiveIndex = _addedAnnotations.indexWhere((annotation) => !annotation.isActive);
    if (firstInactiveIndex != -1) {
      final firstInactiveAnnotation = _addedAnnotations[firstInactiveIndex];
      Offset? position;
      if (firstInactiveAnnotation.annotationType == kTextAnnotation) {
        position = _pluginState.textAnnotationsListNotifier.activateId(firstInactiveAnnotation.id);
      } else if (firstInactiveAnnotation.annotationType == kLineAnnotation) {
        position = _pluginState.lineAnnotationsListNotifier.activateId(firstInactiveAnnotation.id);
      }
      _pluginState.updateUndoRedoEnabledState();
      _pluginState.lastRedoNotifier.value = (
        id: firstInactiveAnnotation.id,
        type: firstInactiveAnnotation.annotationType,
      );
      firstInactiveAnnotation.isActive = true;
      if (position != null && !_pluginState.textFocusNode.hasFocus) {
        _setInitialMoveConditions();
        await _setPdfOffset(position);
      }
    }
  }

  Future<void> _setPdfOffset(Offset position) async {
    final pdfPageSize =
        await _pluginState.pdfViewControllerNotifier.value?.getCurrentPageSize() ?? .zero;
    final pageCount = await _pluginState.pdfViewControllerNotifier.value?.getPageCount() ?? 1;
    final pdfHeightLimit = pageCount * pdfPageSize.height - _overlayHeightScaled;
    final yTranslation = -(position.dy - 100.0) * _devPixRatio;
    final newPdfOffset = _pluginState.pdfOffsetNotifier.value.translate(0.0, yTranslation);
    if (!newPdfOffset.dy.isNegative) {
      // new offset is above pdf top
      _pluginState.pdfOffsetNotifier.value = .zero;
      return;
    }

    if (newPdfOffset.dy < -pdfHeightLimit) {
      // new offset is below pdf bottom
      _pluginState.pdfOffsetNotifier.value = Offset(0.0, -pdfHeightLimit);
      return;
    }

    _pluginState.pdfOffsetNotifier.value = newPdfOffset;
  }

  Future<void> _loadPreviousSave() async {
    _addedAnnotations = await _pluginState.loadPreviousSavedJson(
      pdfPath: widget.pdfPath,
      viewportPosition: _vpPosition,
      scaledOverlayWidth: _overlayWidthScaled,
      shortestSideEstimate: MediaQuery.sizeOf(context).shortestSide,
    );
  }

  Future<SaveStateResult> _saveProgress() async {
    final kbHeight = _pluginState.keyboardHeightNotifier.value;
    if (kbHeight != 0.0) {
      await _handleKeyboardHeight(0.0);
    } else {
      _finaliseTexting();
    }

    return await _pluginState.saveAnnotationsToJson(
      pdfPath: widget.pdfPath,
      viewportPosition: _vpPosition,
      scaledOverlayWidth: _overlayWidthScaled,
      addedAnnotations: _addedAnnotations,
    );
  }
}
