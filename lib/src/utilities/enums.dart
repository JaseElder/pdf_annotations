enum QualityValue {
  /// Drawing annotations are displayed and saved as line segments
  low,

  /// Drawing annotations are displayed and saved as quadratic beziers
  high,
}

enum EditMode {
  /// The mode for text input
  text,

  /// The mode for drawing annotations
  draw,

  /// The mode for pdf panning and scrolling
  pan,
}

enum LineMode {
  /// Thin opaque line
  pen,

  /// Thick translucent line
  highlighter,
}

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
