import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart' as pdf_view;
import 'package:transparent_pointer/transparent_pointer.dart';

import '../../data/models/pdf_font.dart';
import '../../data/models/plugin_state.dart';
import '../../data/repositories/pdf_annotations_repository_impl.dart';
import '../../utilities/constants.dart';
import '../../utilities/enums.dart';
import '../../utilities/logger.dart';
import 'drawing_overlay.dart';
import 'pdf_doc_view.dart';

typedef ZoomUpdateCallback = void Function(double newZoom);
typedef DefaultScaleUpdateCallback = void Function(double newScale);
typedef OffsetChangedCallback = void Function(Offset newOffset);
typedef TextFieldShowingCallback = void Function(bool showing);

class PdfAnnotationsViewController {
  late Future<void> Function() undo;
  late Future<void> Function() redo;
  late Future<bool> Function() saveAnnotations;
  late void Function(Color colour) setAnnotationColour;
  late void Function(QualityValue quality) setAnnotationQuality;
  late void Function(LineMode lineMode) setLineMode;
  late void Function(Offset offset) setPosition;
  late Offset Function() getPosition;
  late void Function(EditMode newMode) setEditMode;
  late void Function() setPopInvoked;
  late void Function(double fontSize) setFontSize;
  late void Function(String fontFamily) setFontFamily;
  late void Function() keyboardDismissed;
  late void Function(double height) setKeyboardHeight;
  late Future<bool> Function(List<PdfFont>) registerFonts;
  void Function(bool isAvailable)? onUndoAvailabilityChanged;
  void Function(bool isAvailable)? onRedoAvailabilityChanged;
}

class PdfAnnotationsView extends StatefulWidget {
  const PdfAnnotationsView({
    super.key,
    this.savedAnnotationsJsonSuffix = '_saved_annotations.json',
    this.bakedPdfSuffix = '_annotated.pdf',
    required this.pdfPath,
    required this.pdfDefaultScale,
    required this.startPage,
    required this.initialOffset,
    required this.initialAnnotationColour,
    this.draggingTextFieldBackgroundColour = Colors.black,
    required this.initialFontSize,
    required this.initialFontFamily,
    required this.pdfZoom,
    required this.pdfAnnotationsViewController,
    required this.onZoomUpdate,
    required this.onDefaultScaleUpdate,
    this.progressIndicatorColour = Colors.black,
    this.onPageChanged,
    this.onOffsetChanged,
    this.onTextFieldShowing,
    this.onError,
    this.onPageError,
  });

  final String savedAnnotationsJsonSuffix;
  final String bakedPdfSuffix;
  final String pdfPath;
  final double pdfDefaultScale;
  final int startPage;
  final Offset initialOffset;
  final Color initialAnnotationColour;
  final double initialFontSize;
  final String initialFontFamily;
  final Color draggingTextFieldBackgroundColour;
  final Color progressIndicatorColour;
  final double pdfZoom;
  final PdfAnnotationsViewController pdfAnnotationsViewController;
  final PageChangedCallback? onPageChanged;
  final ZoomUpdateCallback onZoomUpdate;
  final DefaultScaleUpdateCallback onDefaultScaleUpdate;
  final OffsetChangedCallback? onOffsetChanged;
  final TextFieldShowingCallback? onTextFieldShowing;
  final ErrorCallback? onError;
  final PageErrorCallback? onPageError;

  @override
  State<PdfAnnotationsView> createState() => _PdfAnnotationsViewState();
}

class _PdfAnnotationsViewState extends State<PdfAnnotationsView>
    with SingleTickerProviderStateMixin {
  late final PluginState _pluginState;
  late PdfDocViewController _pdfDocViewController;
  late DrawingOverlayController _drawingOverlayController;

  late final pdf_view.PDFViewController? _pdfViewController;
  var _isProgressVisible = true;
  var _showExitProgress = false;
  late final AnimationController _animationController;
  late Animation<Offset> _pdfScrollAnimation;
  late double _devPixRatio;

  List<PdfFont> _fontList = [];
  bool _editModeChanged = false;

  @override
  void initState() {
    super.initState();
    _pluginState = PluginState(
      savedAnnotationsJsonSuffix: widget.savedAnnotationsJsonSuffix,
      initialOffset: widget.initialOffset,
      initialAnnotationColour: widget.initialAnnotationColour,
      draggingTextFieldBackgroundColour: widget.draggingTextFieldBackgroundColour,
      initialFontSize: widget.initialFontSize,
      initialFontFamily: widget.initialFontFamily,
    );
    _pdfDocViewController = PdfDocViewController();
    _drawingOverlayController = DrawingOverlayController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: kAnnotationsAnimationDuration),
      vsync: this,
    );

    widget.pdfAnnotationsViewController.saveAnnotations = _saveAndAddAnnotations;
    widget.pdfAnnotationsViewController.registerFonts = _registerFonts;
    widget.pdfAnnotationsViewController.undo = _undo;
    widget.pdfAnnotationsViewController.redo = _redo;
    widget.pdfAnnotationsViewController.setAnnotationColour = _setAnnotationColour;
    widget.pdfAnnotationsViewController.setAnnotationQuality = _setAnnotationQuality;
    widget.pdfAnnotationsViewController.setLineMode = _setLineMode;
    widget.pdfAnnotationsViewController.setPosition = _setOffset;
    widget.pdfAnnotationsViewController.getPosition = _getOffset;
    widget.pdfAnnotationsViewController.setEditMode = _setEditMode;
    widget.pdfAnnotationsViewController.setFontSize = _setFontSize;
    widget.pdfAnnotationsViewController.setFontFamily = _setFontFamily;
    widget.pdfAnnotationsViewController.setKeyboardHeight = _setKeyboardHeight;
    widget.pdfAnnotationsViewController.keyboardDismissed = _keyboardDismissed;
    widget.pdfAnnotationsViewController.setPopInvoked = _setPopInvoked;

    _pluginState.textFieldShowingNotifier.addListener(_setTextFieldShowing);
    _pluginState.undoEnabledNotifier.addListener(_onUndoAvailabilityChanged);
    _pluginState.redoEnabledNotifier.addListener(_onRedoAvailabilityChanged);
  }

  @override
  void dispose() {
    _pluginState.textFieldShowingNotifier.removeListener(_setTextFieldShowing);
    _pluginState.undoEnabledNotifier.removeListener(_onUndoAvailabilityChanged);
    _pluginState.redoEnabledNotifier.removeListener(_onRedoAvailabilityChanged);
    _pdfDocViewController.dispose();
    _drawingOverlayController.dispose();
    _animationController.dispose();
    _pluginState.dispose();
    super.dispose();
  }

  void _onViewCreated(pdf_view.PDFViewController controller) {
    _pluginState.pdfViewControllerNotifier.value = controller;
    _pdfViewController = controller;
  }

  Future<void> _onRender(int? pages) async {
    if (!mounted || _pdfViewController == null) return;

    _pdfViewController.setZoomLimits(1.0, 1.0, 1.0);
    setState(() {
      _isProgressVisible = false;
    });
    // reset the pdf offset in case the pdf on the live view was zoomed
    var zoom = widget.pdfZoom;
    final pdfOffset = widget.initialOffset;
    var pdfDefaultScale = widget.pdfDefaultScale;

    if (pdfDefaultScale == 0.0 || zoom == 0.0) {
      final vpScale = await _pdfViewController.getScale();
      pdfDefaultScale = _updateDefaultScaleIfNeeded(pdfDefaultScale, vpScale);
      zoom = _updateZoomIfNeeded(zoom, vpScale);
    }

    if (zoom == 0.0) {
      return;
    }
    final pdfOffsetNormalised = Offset(0.0, (pdfOffset.dy * pdfDefaultScale) / zoom);
    _pluginState.pdfOffsetNotifier.value = pdfOffsetNormalised;
    await _pdfViewController.setPosition(pdfOffsetNormalised);
    await _pdfViewController.setScale(pdfDefaultScale);
    widget.onOffsetChanged?.call(pdfOffsetNormalised);
  }

  Future<void> _onPageChanged(int page) async {
    widget.onPageChanged?.call(page);
  }

  double _updateDefaultScaleIfNeeded(double pdfDefaultScale, double vpScale) {
    if (pdfDefaultScale == 0.0) {
      widget.onDefaultScaleUpdate(vpScale);
      return vpScale;
    }
    return pdfDefaultScale;
  }

  double _updateZoomIfNeeded(double zoom, double vpScale) {
    if (zoom == 0.0) {
      widget.onZoomUpdate(vpScale);
      return vpScale;
    }
    return zoom;
  }

  Future<void> _onDraw({required Offset position, required double scale}) async {
    if (!mounted) return;

    if (_editModeChanged) {
      await _pdfViewController?.setPosition(_pluginState.pdfOffsetNotifier.value);
      _editModeChanged = false;
    } else {
      if (_pluginState.pdfOffsetNotifier.value != position) {
        _pluginState.pdfOffsetNotifier.value = position;
        widget.onOffsetChanged?.call(position);
      }
    }
  }

  void _setTextFieldShowing() =>
      widget.onTextFieldShowing?.call(_pluginState.textFieldShowingNotifier.value);

  void _onUndoAvailabilityChanged() {
    widget.pdfAnnotationsViewController.onUndoAvailabilityChanged?.call(
      _pluginState.undoEnabledNotifier.value,
    );
  }

  void _onRedoAvailabilityChanged() {
    widget.pdfAnnotationsViewController.onRedoAvailabilityChanged?.call(
      _pluginState.redoEnabledNotifier.value,
    );
  }

  void _onError(dynamic error) => widget.onError?.call(error);

  void _onPageError(int? page, dynamic error) => widget.onPageError?.call(page, error);

  Future<bool> _registerFonts(List<PdfFont> fontList) async {
    _fontList = fontList;
    return await PdfAnnotationsRepositoryImpl().registerFonts(fontList);
  }

  Future<void> _undo() async {
    await _drawingOverlayController.undo();
    _pdfViewController?.setPosition(_pluginState.pdfOffsetNotifier.value);
  }

  Future<void> _redo() async {
    await _drawingOverlayController.redo();
    _pdfViewController?.setPosition(_pluginState.pdfOffsetNotifier.value);
  }

  void _setAnnotationColour(Color colour) {
    _pluginState.annotationColourNotifier.value = colour;
  }

  void _setAnnotationQuality(QualityValue quality) {
    _pluginState.annotationQualityNotifier.value = quality;
  }

  void _setLineMode(LineMode lineMode) {
    _pluginState.lineModeNotifier.value = lineMode;
  }

  void _setOffset(Offset offset) {
    _pluginState.pdfOffsetNotifier.value = offset;
  }

  Offset _getOffset() => _pluginState.pdfOffsetNotifier.value;

  void _setEditMode(EditMode mode) {
    _editModeChanged = _pluginState.editMode != mode;
    _pluginState.editMode = mode;
  }

  void _setFontSize(double fontSize) {
    _pluginState.fontSizeNotifier.value = fontSize;
  }

  void _setFontFamily(String fontFamily) {
    _pluginState.fontFamilyNotifier.value = fontFamily;
  }

  void _setKeyboardHeight(double newHeight) {
    _pluginState.keyboardHeightNotifier.value = newHeight;
  }

  void _setPopInvoked() {
    _pluginState.popInvokedNotifier.value = true;
    setState(() {
      _showExitProgress = true;
    });
  }

  void _keyboardDismissed() {
    _pluginState.textFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    _devPixRatio = MediaQuery.devicePixelRatioOf(context);
    return PluginStateProvider(
      _pluginState,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PdfDocView(
                  pdfPath: widget.pdfPath,
                  defaultPage: widget.startPage,
                  onViewCreated: _onViewCreated,
                  onRender: _onRender,
                  onDraw: _onDraw,
                  onPageChanged: _onPageChanged,
                  onError: _onError,
                  onPageError: _onPageError,
                ),
              ),
              SizedBox(
                width: .infinity,
                height: _pluginState.cursorAdjustmentForKeyboardHeightNotifier.value,
              ),
            ],
          ),
          Visibility(
            visible: !_isProgressVisible,
            child: TransparentPointer(
              transparent: Platform.isAndroid || _pluginState.editMode == .pan,
              child: DrawingOverlay(
                drawingOverlayController: _drawingOverlayController,
                pdfPath: widget.pdfPath,
                onInsertionPointModified: _onInsertionPointModified,
                onError: _onError,
              ),
            ),
          ),
          Visibility(
            visible: _isProgressVisible || _showExitProgress,
            child: Container(
              width: .infinity,
              height: .infinity,
              color: _showExitProgress ? Colors.white : Colors.transparent,
              child: Center(
                child: CircularProgressIndicator(color: widget.progressIndicatorColour),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onInsertionPointModified(double adjustedHeight) async {
    if (_pdfViewController == null) {
      return;
    }
    final vpPosition = await _pdfViewController.getPosition();
    final finishingYPos = vpPosition.dy - adjustedHeight * _devPixRatio;

    if (_pluginState.popInvokedNotifier.value) {
      _pdfViewController.setPosition(Offset(0.0, finishingYPos));
    } else {
      _animatePdfScroll(vpPosition, Offset(vpPosition.dx, finishingYPos));
    }
  }

  void _animatePdfScroll(Offset begin, Offset end) {
    _pdfScrollAnimation = Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.decelerate));

    _pdfScrollAnimation.addListener(_applyTransform);

    _animationController.reset();
    _animationController.forward();
  }

  void _applyTransform() => _pdfViewController?.setPosition(_pdfScrollAnimation.value);

  Future<bool> _saveAndAddAnnotations() async {
    final annotationsSavedToJsonResult = await _drawingOverlayController
        .saveAnnotationsToJsonFile();

    switch (annotationsSavedToJsonResult) {
      case .fileDeleted:
        final pdfPath = widget.pdfPath;
        if (pdfPath.isNotEmpty) {
          await _createBakedFile(pdfPath);
        }
        _pdfDocViewController.setNewlyEdited();
        return true;
      case .fileCreated:
      case .fileUpdated:
        try {
          var result = await _addAnnotationsToPdf();
          if (result) {
            _pdfDocViewController.setNewlyEdited();
          }
          return result;
        } on Exception {
          rethrow;
        }
      case .noChange:
      case .error:
        return false;
    }
  }

  Future<bool> _addAnnotationsToPdf() async {
    logger.w('start add annotations ${DateTime.now()}');
    if (_pdfViewController == null) {
      return false;
    }
    final (currentPageSize, position) = await (
      _pdfViewController.getCurrentPageSize(),
      _pdfViewController.getPosition(),
    ).wait;
    final noOfPages = await _pdfViewController.getPageCount() ?? 1;
    final double overlayScale =
        currentPageSize.width / (_drawingOverlayController.getOverlayWidthScaled());
    var vpOffset = -position;
    if (Platform.isIOS) {
      vpOffset *= overlayScale;
    }
    final pdfPath = widget.pdfPath;
    if (pdfPath == '') {
      return false;
    }
    final bakedPath = await _createBakedFile(pdfPath);
    try {
      bool result = await PdfAnnotationsRepositoryImpl().addAnnotations(
        fileName: bakedPath,
        lineAnnotations: _pluginState.lineAnnotationsListNotifier.value,
        textAnnotations: _pluginState.textAnnotationsListNotifier.value,
        fonts: _fontList,
        pdfPageDims: Offset(currentPageSize.width, currentPageSize.height),
        totalPdfLength: currentPageSize.height * noOfPages,
        viewportOffset: vpOffset,
        overlayScale: overlayScale * _devPixRatio,
      );
      logger.w('end add annotations ${DateTime.now()}');
      return result;
    } on Exception {
      rethrow;
    }
  }

  Future<String> _createBakedFile(String pdfPath) async {
    final file = File(pdfPath);
    final bakedPath = pdfPath.replaceAll(kPdfSuffix, widget.bakedPdfSuffix);
    await file.copy(bakedPath);
    return bakedPath;
  }
}
