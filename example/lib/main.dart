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
  String _originalPdfPath = '';
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
      final modifiedFile = File('${dir.path}/sample_annotated.pdf');

      _originalPdfPath = _pdfPath = file.path;
      if (await file.exists()) {
        if (await modifiedFile.exists()) {
          _pdfPath = modifiedFile.path;
        }
      } else {
        // Copy from assets to local file system so it can be accessed by path
        final data = await rootBundle.load('assets/sample.pdf');
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes, flush: true);
      }
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
    return SafeArea(
      child: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : Scaffold(
              appBar: AppBar(
                title: const Text('PDF Annotations Example'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPage(
                              pdfPath: _originalPdfPath,
                              pdfZoom: _pdfScale,
                              pdfOffset: _pdfOffset,
                            ),
                          ),
                        ).then((result) {
                          if (result is String) {
                            setState(() {
                              if (result.isNotEmpty) {
                                _pdfPath = result;
                              } else {
                                _pdfPath = _originalPdfPath;
                              }
                            });
                          }
                        }),
                  ),
                ],
              ),
              body: PDFView(
                key: UniqueKey(),
                filePath: _pdfPath,
                pageFling: false,
                pageSnap: false,
                autoSpacing: false,
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

  EditMode _editMode = .pan;
  LineMode _lineMode = .pen;
  String _fontFamily = 'Google Sans';
  double _fontSize = 18.0;
  QualityValue _annotationQuality = .high;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
                  PdfFont(family: 'Google Sans', fileName: 'GoogleSans-Regular.ttf'),
                  PdfFont(family: 'Courier Prime', fileName: 'CourierPrime-Regular.ttf'),
                ];
                await _controller.registerFonts(pdfFonts);
                await _controller.saveAnnotations();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Annotations saved!')));
                  Navigator.pop(context, _controller.getBakedPath());
                }
              },
            ),
          ],
        ),
        body: _pdfPath.isEmpty
            ? const Center(child: Text('No PDF file found. Please add sample.pdf'))
            : Column(
                children: [
                  Column(
                    mainAxisAlignment: .center,
                    children: [
                      SegmentedButton<QualityValue>(
                        segments: <ButtonSegment<QualityValue>>[
                          ButtonSegment<QualityValue>(value: .low, label: const Text('Low')),
                          ButtonSegment<QualityValue>(value: .high, label: const Text('High')),
                        ],
                        selected: <QualityValue>{_annotationQuality},
                        onSelectionChanged: (Set<QualityValue> newSelection) {
                          setState(() {
                            _annotationQuality = newSelection.first;
                          });
                          _controller.setAnnotationQuality(_annotationQuality);
                        },
                      ),
                      SegmentedButton<EditMode>(
                        segments: const <ButtonSegment<EditMode>>[
                          ButtonSegment<EditMode>(
                            value: .draw,
                            label: Text('Draw'),
                            icon: Icon(Icons.edit),
                          ),
                          ButtonSegment<EditMode>(
                            value: .text,
                            label: Text('Text'),
                            icon: Icon(Icons.text_fields),
                          ),
                          ButtonSegment<EditMode>(
                            value: .pan,
                            label: Text('Pan'),
                            icon: Icon(Icons.pan_tool),
                          ),
                        ],
                        selected: <EditMode>{_editMode},
                        onSelectionChanged: (Set<EditMode> newSelection) {
                          setState(() {
                            _editMode = newSelection.first;
                          });
                          _controller.setEditMode(_editMode);
                          if (_editMode == .text) {
                            _controller.setFontFamily(_fontFamily);
                          }
                        },
                      ),
                      _editMode == .draw
                          ? SegmentedButton<LineMode>(
                              segments: <ButtonSegment<LineMode>>[
                                ButtonSegment<LineMode>(value: .pen, label: const Text('Pen')),
                                ButtonSegment<LineMode>(
                                  value: .highlighter,
                                  label: const Text('Highlighter'),
                                ),
                              ],
                              selected: <LineMode>{_lineMode},
                              onSelectionChanged: (Set<LineMode> newSelection) {
                                setState(() {
                                  _lineMode = newSelection.first;
                                });
                                _controller.setLineMode(_lineMode);
                              },
                            )
                          : _editMode == .text
                          ? Row(
                              mainAxisSize: .min,
                              children: [
                                SegmentedButton<String>(
                                  segments: <ButtonSegment<String>>[
                                    ButtonSegment<String>(
                                      value: 'Google Sans',
                                      label: const Text('Google Sans'),
                                    ),
                                    ButtonSegment<String>(
                                      value: 'Courier Prime',
                                      label: const Text('Courier'),
                                    ),
                                  ],
                                  selected: <String>{_fontFamily},
                                  onSelectionChanged: (Set<String> newSelection) {
                                    setState(() {
                                      _fontFamily = newSelection.first;
                                    });
                                    _controller.setFontFamily(_fontFamily);
                                  },
                                ),
                                Slider(
                                  min: 10.0,
                                  max: 40.0,
                                  divisions: 30,
                                  value: _fontSize,
                                  onChanged: (newSize) {
                                    setState(() {
                                      _fontSize = newSize;
                                    });
                                    _controller.setFontSize(_fontSize);
                                  },
                                ),
                              ],
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                  Expanded(
                    child: PdfAnnotationsView(
                      pdfPath: _pdfPath,
                      startPage: 0,
                      initialOffset: widget.pdfOffset,
                      initialAnnotationColour: Colors.red,
                      initialFontSize: _fontSize,
                      initialFontFamily: _fontFamily,
                      pdfZoom: widget.pdfZoom,
                      pdfAnnotationsViewController: _controller,
                      onAnnotationQualityChanged: _onAnnotationQualityChanged,
                      onPageChanged: (page) => debugPrint('Page: $page'),
                      onError: (error) => debugPrint('Error: $error'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _onAnnotationQualityChanged(QualityValue quality) {
    setState(() {
      _annotationQuality = quality;
    });
  }
}
