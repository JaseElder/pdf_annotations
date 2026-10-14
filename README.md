# pdf_annotations

[![pub package](https://img.shields.io/pub/v/pdf_annotations.svg)](https://pub.dev/packages/pdf_annotations)
[![GitHub License](https://img.shields.io/github/license/JaseElder/pdf_annotations)](https://github.com/JaseElder/pdf_annotations/blob/main/LICENSE)
[![platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-green.svg)](https://pub.dev/packages/pdf_annotations)

A Flutter plugin for adding text and freehand annotations to PDF documents. This plugin was created to avoid having to use an external subscription-based solution.

This package provides a `PdfAnnotationsView` widget that displays a PDF and allows users to draw lines (pen/highlighter) and add text annotations on top of it. It supports panning, undo/redo, and saving the annotations back to a new PDF file.

The widget is UI agnostic. Add your own UI (a rudimentary one is showcased in the example code), and communicate changes through the `PdfAnnotationsViewController`.

## Features

*   **View PDFs**: Render PDF documents with zoom and pan capabilities.
*   **Freehand Drawing**: Draw on the PDF using a pen or highlighter tool.
*   **Text Annotations**: Add text to the PDF. Drag and drop the current text annotation to move it around the PDF.
*   **Customization**: enhancing color, stroke width, font size, and font family.
*   **Undo/Redo**: robust state management for annotation actions.
*   **Save & Export**: Merge annotations into the PDF and save as a new file.

## Getting Started

Add `pdf_annotations` to your `pubspec.yaml`:

```yaml
dependencies:
  pdf_annotations: ^1.0.2
```

## Usage

Import the package:

```dart
import 'package:pdf_annotations/pdf_annotations.dart';
```

Use the `PdfAnnotationsView` widget in your widget tree. You need to provide a `PdfAnnotationsViewController` to control the view's actions.

```dart
import 'package:flutter/material.dart';
import 'package:pdf_annotations/pdf_annotations.dart';

class MyPdfViewer extends StatefulWidget {
  final String pdfPath;

  const MyPdfViewer({super.key, required this.pdfPath});

  @override
  State<MyPdfViewer> createState() => _MyPdfViewerState();
}

class _MyPdfViewerState extends State<MyPdfViewer> {
  final PdfAnnotationsViewController _controller = PdfAnnotationsViewController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annotate PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => _controller.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () => _controller.redo(),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await _controller.saveAnnotations();
              // The original file is not overwritten by default, check specific implementation details.
            },
          ),
        ],
      ),
      body: PdfAnnotationsView(
        pdfPath: widget.pdfPath,
        // Suffix for the current annotations JSON file. This enables saving session state. 
        // Default value is '_saved_annotations.json'
        savedAnnotationsJsonSuffix: '_anns.json',
        // Suffix for the newly annotated PDF file. It is appended to the current PDF file name. 
        // Default value is '_annotated.pdf'
        bakedPdfSuffix: '_anns.pdf',
        startPage: 0,
        // The initial scroll offset of the view. 
        // This is to account for coming to the edit screen from a scrolled pdf
        initialOffset: Offset.zero,
        initialAnnotationColour: Colors.red,
        initialFontSize: 14.0,
        initialFontFamily: 'Arial',
        // The text annotation is draggable. This specifies the colour of the widget background.
        // Default is Colors.black
        draggingTextFieldBackgroundColour: Colors.green,
        // Default is Colors.black
        progressIndicatorColour: Colors.orange,
        // If the pdf to be edited was zoomed in, the widget will unzoom and scale annotations
        // appropriately. This parameter specifies what the pdf zoom level was on entering the 
        // edit widget.
        pdfZoom: 1.0,
        pdfAnnotationsViewController: _controller,
        onPageChanged: (page) {
          print('Page changed to: $page');
        },
        // This callback enables tracking of any offset changes in the edit, to communicate back 
        // to a pdf view widget and alter its offset.
        onOffsetChanged: (offset) {
          print('Offset changed to: $offset');
        },
        onTextFieldShowing: (isShowing) {
          print('Text field is showing: $isShowing');
        },
        onAnnotationQualityChanged: (newQuality) {
          print('Annotation quality has changed to: $newQuality');
        },
        onError: (error) {
          print('Error: $error');
        },
        onPageError: (pageNo, error) {
          print('Page $pageNo has error: $error');
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _controller.setEditMode(EditMode.draw),
            ),
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: () => _controller.setEditMode(EditMode.text),
            ),
            IconButton(
              icon: const Icon(Icons.pan_tool),
              onPressed: () => _controller.setEditMode(EditMode.pan),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Controller Methods

The `PdfAnnotationsViewController` exposes several methods to interact with the view programmatically:

*   `undo()`: Undo the last annotation action.
*   `redo()`: Redo the last undone action.
*   `saveAnnotations()`: Save the current annotations to the file system.
*   `setAnnotationColour(Color color)`: Change the current drawing/text color.
*   `setLineMode(LineMode mode)`: Switch between `.pen` and `.highlighter`.
*   `setEditMode(EditMode mode)`: Switch between `.text`, `.draw`, and `.pan` modes.
*   `setFontSize(double size)`: Set the font size for text annotations.
*   `setFontFamily(String family)`: Set the font family for text annotations.

## Contribution

Contributions are welcome! If you find a bug or want to add a feature, please feel free to open an issue or submit a pull request.

## License

This project is licensed under the 3-clause BSD License - see the [LICENSE](LICENSE) file for details.
