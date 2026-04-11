enum QualityValue { low, high }

enum EditMode { text, draw, pan }

enum LineMode { pen, highlighter }

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
