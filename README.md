# pdf_annotations

A Flutter plugin for adding text and freehand annotations to PDF documents.

This package provides a `PdfAnnotationsView` widget that displays a PDF and allows users to draw lines (pen/highlighter) and add text annotations on top of it. It supports zooming, panning, undo/redo, and saving the annotations back to a new PDF file.

## Features

*   **View PDFs**: Render PDF documents with zoom and pan capabilities.
*   **Freehand Drawing**: Draw on the PDF using a pen or highlighter tool.
*   **Text Annotations**: Add text labels at specific locations.
*   **Customization**: enhancing color, stroke width, font size, and font family.
*   **Undo/Redo**: robust state management for annotation actions.
*   **Save & Export**: Merge annotations into the PDF and save as a new file.

## Getting Started

Add `pdf_annotations` to your `pubspec.yaml`:

```yaml
dependencies:
  pdf_annotations: ^1.0.0
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
        pdfDefaultScale: 1.0,
        startPage: 0,
        initialOffset: Offset.zero,
        initialAnnotationColour: Colors.red,
        initialFontSize: 14.0,
        initialFontFamily: 'Arial',
        pdfZoom: 1.0,
        pdfAnnotationsViewController: _controller,
        onZoomUpdate: (zoom) {
          // Handle zoom update
        },
        onDefaultScaleUpdate: (scale) {
          // Handle scale update
        },
        onPageChanged: (page) {
          print('Page changed to: $page');
        },
        onError: (error) {
          print('Error: $error');
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
*   `setLineMode(LineMode mode)`: Switch between `pen` and `highlighter`.
*   `setEditMode(EditMode mode)`: Switch between `text`, `draw`, and `pan` modes.
*   `setFontSize(double size)`: Set the font size for text annotations.
*   `setFontFamily(String family)`: Set the font family for text annotations.

## Contribution

Contributions are welcome! If you find a bug or want to add a feature, please feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
