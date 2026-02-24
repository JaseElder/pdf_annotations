/// A Flutter plugin for viewing and annotating PDF files.
///
/// This package provides the [PdfAnnotationsView] widget, which renders a PDF document
/// and allows the user to perform freehand drawing and add text annotations.
///
/// The view is controlled via [PdfAnnotationsViewController], which exposes methods for
/// undo/redo, changing annotation properties (color, font size, etc.), and saving the
/// annotations back to the file system.
library;

export 'src/data/models/pdf_font.dart';
export 'src/presentation/widgets/pdf_annotations_view.dart';
export 'src/utilities/enums.dart';
