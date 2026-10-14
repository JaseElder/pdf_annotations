import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

typedef ViewCreatedCallback = void Function(PdfViewerController controller);
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
    this.onDraw,
    this.onError,
    this.onPageError,
  });

  @override
  State<PdfDocView> createState() => _PdfDocViewState();
}

class _PdfDocViewState extends State<PdfDocView> {
  PdfViewerController? _pdfViewerController;
  var _key = UniqueKey();

  int _pageIndex = 0;

  late final PdfViewerParams _pdfViewerParams = PdfViewerParams(
    margin: 0.0,
    scaleEnabled: false,
    annotationRenderingMode: .annotation,
    onViewerReady: (document, controller) {
      _handleViewCreated(controller);
      widget.onRender(document.pages.length);
    },
    onPageChanged: _handlePageChanged,
    errorBannerBuilder: (context, error, stackTrace, documentRef) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleError(error);
      });
      return Center(
        child: Text('Error loading PDF: $error', style: const TextStyle(color: Colors.red)),
      );
    },
  );

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pdfPath = widget.pdfPath;

    if (pdfPath.isNotEmpty) {
      return PdfViewer.file(
        pdfPath,
        key: _key,
        initialPageNumber: widget.defaultPage,
        params: _pdfViewerParams,
      );
    }

    return const Text('No file', style: TextStyle(color: Colors.red));
  }

  void setNewlyEdited() {
    _key = UniqueKey();
  }

  void _handlePageChanged(int? page) {
    _pageIndex = page ?? 0;
    widget.onPageChanged?.call(_pageIndex);
  }

  void _handleViewCreated(PdfViewerController pdfViewController) {
    _pdfViewerController = pdfViewController;
    _pdfViewerController?.goToPage(pageNumber: _pageIndex);
    if (_pdfViewerController != null) {
      widget.onViewCreated?.call(_pdfViewerController!);

      _pdfViewerController!.addListener(() async {
        final zoom = _pdfViewerController!.currentZoom;
        final matrix = _pdfViewerController!.value;
        final xOffset = matrix.getTranslation().x;
        final yOffset = matrix.getTranslation().y;

        await widget.onDraw?.call(position: Offset(xOffset, yOffset), scale: zoom);
      });
    }
  }

  void _handleError(dynamic error) => widget.onError?.call(error);
}
