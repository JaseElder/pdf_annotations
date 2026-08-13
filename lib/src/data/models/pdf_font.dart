/// Represents a font configuration used for rendering text annotations
/// into the PDF document.
///
/// This class maps a Flutter-side [family] name to the [fileName] or
/// PostScript name required by the native PDF engine.
class PdfFont {
  /// The name of the font family as defined in your Flutter project
  /// (e.g., 'Roboto', 'OpenSans').
  String family;

  /// The name of the font file or the internal PostScript name
  /// recognized by the native PDF renderer.
  ///
  /// On iOS, this should be the PostScript name of the font.
  /// On Android, this refers to the font's filename as registered
  /// with the system.
  String fileName;

  /// Creates a new [PdfFont] mapping.
  PdfFont({required this.family, required this.fileName});
}
