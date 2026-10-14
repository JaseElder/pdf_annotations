## 1.0.2

* moved from `flutter_pdfview` library to `pdfrx` library as the underlying Android native `AndroidPdfViewer` has problems with very large pdfs.
* added more tests for coverage.
* Updated dependencies.

## 1.0.1

* Updated dependencies.

## 1.0.0+2

* Fixed example usage code in README.md.

## 1.0.0+1

* Fixed version typo in README.md.

## 1.0.0

* upgraded dependencies, including `flutter_pdfview` to non-beta version.
* removed generate_all_pigeons shell script and replaced it with tool/generate.dart to generate the pigeon api, reformat it to meet pana requirements, and remove the meta dependency.

## 1.0.0-beta.4

* Updates minimum supported SDK version to Flutter 3.44/Dart 3.12.
* Migrates to built-in Kotlin
* Added SPM support

## 1.0.0-beta.3

* Updated flutter_pdfview dependency.


## 1.0.0-beta.2

* Updated read me and description.


## 1.0.0-beta.1

*   Initial release with `PdfAnnotationsView` widget.
*   Support for freehand drawing (Pen, Highlighter).
*   Correct text annotation support with custom fonts and sizes.
*   Undo/Redo capabilities.
*   Controller for programmatic interaction.
*   Save annotations state in JSON or merge back to PDF.
