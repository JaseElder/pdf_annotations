import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

typedef ViewCreatedCallback = void Function(PDFViewController controller);
typedef RenderCallback = void Function(int? pages);
typedef PageChangedCallback = void Function(int page);
typedef LoadCompleteCallback = void Function(int? pages);
typedef DrawCallback = Future<void> Function({required Offset position, required double scale});
typedef ErrorCallback = void Function(dynamic error);
typedef PageErrorCallback = void Function(int? page, dynamic error);

class PdfDocViewController extends ChangeNotifier {
  _PdfDocViewState? _state;
  Future<void> Function()? undo;

  void setNewlyEdited() {
    _state?.setNewlyEdited();
  }

  void _attach(_PdfDocViewState state) {
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

class PdfDocView extends StatefulWidget {
  final PdfDocViewController? pdfDocViewController;
  final String pdfPath;
  final int defaultPage;
  final ViewCreatedCallback? onViewCreated;
  final RenderCallback onRender;
  final PageChangedCallback? onPageChanged;
  final LoadCompleteCallback? onLoadComplete;
  final DrawCallback? onDraw;
  final ErrorCallback? onError;
  final PageErrorCallback? onPageError;

  const PdfDocView({
    super.key,
    this.pdfDocViewController,
    required this.pdfPath,
    required this.defaultPage,
    required this.onRender,
    this.onPageChanged,
    this.onViewCreated,
    this.onLoadComplete,
    this.onDraw,
    this.onError,
    this.onPageError,
  });

  @override
  State<PdfDocView> createState() => _PdfDocViewState();
}

class _PdfDocViewState extends State<PdfDocView> {
  late PDFViewController? _pdfViewController;
  var _key = UniqueKey();

  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.pdfDocViewController?._attach(this);
  }

  @override
  void didUpdateWidget(covariant PdfDocView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pdfDocViewController != oldWidget.pdfDocViewController) {
      oldWidget.pdfDocViewController?._detach();
      widget.pdfDocViewController?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.pdfDocViewController?._detach();
    _pdfViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pdfPath = widget.pdfPath;

    if (pdfPath.isNotEmpty) {
      return PDFView(
        key: _key,
        filePath: pdfPath,
        defaultPage: widget.defaultPage,
        pageFling: false,
        pageSnap: false,
        autoSpacing: false,
        preventLinkNavigation: true,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(() => VerticalDragGestureRecognizer()),
        },
        onRender: widget.onRender,
        onLoadComplete: widget.onLoadComplete,
        onDraw: _handleOnDraw,
        onError: _handleError,
        onPageError: _handlePageError,
        onViewCreated: _handleViewCreated,
        onPageChanged: _handlePageChanged,
      );
    }

    return const Text('No file', style: TextStyle(color: Colors.red));
  }

  void setNewlyEdited() {
    _key = UniqueKey();
  }

  void _handlePageChanged(int? page, int? total) {
    _pageIndex = page ?? 0;
    widget.onPageChanged?.call(_pageIndex);
  }

  void _handleViewCreated(PDFViewController pdfViewController) {
    _pdfViewController = pdfViewController;
    _pdfViewController?.setPage(_pageIndex);
    if (_pdfViewController != null) {
      widget.onViewCreated?.call(_pdfViewController!);
    }
  }

  Future<void> _handleOnDraw(double pdfXOffset, double pdfYOffset, double pdfScale) async {
    if (_pdfViewController == null) {
      return;
    }
    // final (Offset position, double scale) = await (
    //   _pdfViewController!.getPosition(),
    //   _pdfViewController!.getScale(),
    // ).wait;
    await widget.onDraw?.call(position: Offset(pdfXOffset, pdfYOffset), scale: pdfScale);
  }

  void _handleError(dynamic error) => widget.onError?.call(error);

  void _handlePageError(int? page, dynamic error) => widget.onPageError?.call(page, error);
}
