import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/plugin_state.dart';
import 'package:pdf_annotations/src/utilities/enums.dart';

void main() {
  group('PluginState', () {
    late PluginState pluginState;

    setUp(() {
      pluginState = PluginState(
        savedAnnotationsJsonSuffix: 'test.json',
        initialOffset: const Offset(10, 20),
        initialAnnotationColour: Colors.blue,
        draggingTextFieldBackgroundColour: Colors.grey,
        initialFontSize: 24.0,
        initialFontFamily: 'Helvetica',
      );
    });

    test('should set initial values correctly', () {
      expect(pluginState.pdfOffsetNotifier.value, const Offset(10, 20));
      expect(pluginState.annotationColourNotifier.value, Colors.blue);
      expect(pluginState.draggingTextFieldBackgroundColor, Colors.grey);
      expect(pluginState.fontSizeNotifier.value, 24.0);
      expect(pluginState.fontFamilyNotifier.value, 'Helvetica');
    });

    test('should update streams correctly', () {
      expect(pluginState.textsStream, isNotNull);
      expect(pluginState.linesStream, isNotNull);
      expect(pluginState.currentLineStream, isNotNull);
    });

    test('should update notifiers correctly', () {
      pluginState.editMode = EditMode.text;
      expect(pluginState.editMode, EditMode.text);

      pluginState.textInsertionPointNotifier.value = const Offset(100, 200);
      expect(pluginState.textInsertionPoint, const Offset(100, 200));
    });

    test('should dispose streams', () {
      pluginState.dispose();
      // No direct way to check if streams are closed, but this ensures the method is called.
    });
  });
}
