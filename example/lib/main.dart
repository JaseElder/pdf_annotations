import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_annotations/pdf_annotations.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _pdfPath = '';
  bool _isLoading = true;
  double _pdfScale = 1.0;
  Offset _pdfOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sample.pdf');

      // Copy from assets to local file system so it can be accessed by path
      final data = await rootBundle.load('assets/sample.pdf');
      final bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);

      _pdfPath = file.path;
    } catch (e) {
      debugPrint('Error initializing PDF: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Annotations Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => EditPage(
                        pdfPath: _pdfPath,
                        pdfZoom: _pdfScale,
                        pdfOffset: _pdfOffset,
                      )),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: PDFView(
          filePath: _pdfPath,
          pageFling: false,
          pageSnap: false,
          onDraw: (double pdfXOffset, double pdfYOffset, double pdfScale) {
            _pdfOffset = Offset(pdfXOffset, pdfYOffset);
            _pdfScale = pdfScale;
          },
          onPageChanged: (page, total) => debugPrint('Page: $page of $total'),
          onError: (error) => debugPrint('Error: $error'),
        ),
      ),
    );
  }
}

class EditPage extends StatefulWidget {
  const EditPage({
    super.key,
    required this.pdfPath,
    required this.pdfOffset,
    required this.pdfZoom,
  });

  final String pdfPath;
  final Offset pdfOffset;
  final double pdfZoom;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final PdfAnnotationsViewController _controller = PdfAnnotationsViewController();

  String get _pdfPath => widget.pdfPath;

  EditMode _editMode = EditMode.pan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Annotations Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () async => await _controller.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () async => await _controller.redo(),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final pdfFonts = [
                PdfFont(family: 'STIXTwoText', fileName: 'STIXTwoText-SemiBold.ttf'),
                PdfFont(family: 'PPPangramSans', fileName: 'PPPangramSans-Extrabold.ttf'),
              ];
              await _controller.registerFonts(pdfFonts);
              await _controller.saveAnnotations();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Annotations saved!')),
                );
              }
            },
          ),
        ],
      ),
      body: _pdfPath.isEmpty
          ? const Center(child: Text('No PDF file found. Please add sample.pdf'))
          : SafeArea(
              child: PdfAnnotationsView(
                pdfPath: _pdfPath,
                startPage: 0,
                initialOffset: widget.pdfOffset,
                initialAnnotationColour: Colors.red,
                initialFontSize: 14.0,
                initialFontFamily: 'Arial',
                pdfZoom: widget.pdfZoom,
                pdfAnnotationsViewController: _controller,
                onPageChanged: (page) => debugPrint('Page: $page'),
                onError: (error) => debugPrint('Error: $error'),
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        child: SegmentedButton<EditMode>(
            segments: const <ButtonSegment<EditMode>>[
              ButtonSegment<EditMode>(
                value: EditMode.draw,
                label: Text('Draw'),
                icon: Icon(Icons.edit),
              ),
              ButtonSegment<EditMode>(
                value: EditMode.text,
                label: Text('Text'),
                icon: Icon(Icons.text_fields),
              ),
              ButtonSegment<EditMode>(
                value: EditMode.pan,
                label: Text('Pan'),
                icon: Icon(Icons.pan_tool),
              ),
            ],
            selected: <EditMode>{
              _editMode
            },
            onSelectionChanged: (Set<EditMode> newSelection) {
              setState(() {
                _editMode = newSelection.first;
                _controller.setEditMode(_editMode);
              });
            }),
      ),
    );
  }
}
