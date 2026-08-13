/// Defines the rendering and persistence quality for drawing annotations.
enum QualityValue {
  /// Drawing annotations are displayed and saved as line segments.
  low,

  /// Drawing annotations are displayed and saved as quadratic beziers.
  high,
}

/// Represents the current interaction state of the PDF editing widget.
enum EditMode {
  /// Allows the user to place text annotations.
  text,

  /// Enables freehand drawing using the currently selected [LineMode].
  draw,

  /// Disables annotation tools to allow for standard PDF navigation,
  /// including panning and scrolling.
  pan,
}

/// Specifies the visual style and behavior of drawing strokes.
enum LineMode {
  /// Thin opaque line for sketching.
  pen,

  /// A thick, semi-transparent line designed to emphasize underlying text
  /// without obscuring it.
  highlighter,
}

/// The result of a state persistence operation.
enum SaveStateResult {
  /// The state was successfully saved to a new file.
  fileCreated,

  /// The state was successfully saved by overwriting an existing file.
  fileUpdated,

  /// The state file was successfully deleted because no annotations were active.
  fileDeleted,

  /// No action was taken because the on-disk state was already up-to-date.
  noChange,
}
