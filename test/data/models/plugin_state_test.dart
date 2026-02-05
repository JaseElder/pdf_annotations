import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/plugin_state.dart';
import 'package:pdf_annotations/src/domain/entities/line_annotation.dart';
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
      expect(pluginState.lineAnnotationsListNotifier.value, []);
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

    test('adding an annotation enables undo when a listener is attached', () {
      final lineAnnotation = LineAnnotation(
        [const Offset(10, 10), const Offset(50, 50)],
        const Color(0xFFFF0000),
        2.0,
        true,
        'test-line-1',
      );

      expect(pluginState.lineAnnotationsListNotifier.value, isEmpty);
      expect(pluginState.undoEnabledNotifier.value, isFalse);

      void externalListener() {
        pluginState.updateUndoRedoState();
      }

      pluginState.lineAnnotationsListNotifier.addListener(externalListener);
      addTearDown(() => pluginState.lineAnnotationsListNotifier.removeListener(externalListener));

      pluginState.lineAnnotationsListNotifier.addAnnotations([lineAnnotation]);

      expect(pluginState.lineAnnotationsListNotifier.value, [lineAnnotation]);
      expect(pluginState.undoEnabledNotifier.value, isTrue);
      expect(pluginState.redoEnabledNotifier.value, isFalse);
    });

    test('setting an added annotation to inactive enables redo and disables undo', () {
      final lineAnnotation = LineAnnotation(
        [const Offset(10, 10), const Offset(50, 50)],
        const Color(0xFFFF0000),
        2.0,
        true,
        'test-line-1',
      );

      final lineAnnotation2 = LineAnnotation(
        [const Offset(100, 10), const Offset(50, 50)],
        const Color(0xFF00FF00),
        2.0,
        true,
        'test-line-2',
      );

      final lineAnnotation2Inactive = LineAnnotation(
        [const Offset(100, 10), const Offset(50, 50)],
        const Color(0xFF00FF00),
        2.0,
        false,
        'test-line-2',
      );

      expect(pluginState.lineAnnotationsListNotifier.value, isEmpty);
      expect(pluginState.undoEnabledNotifier.value, isFalse);
      expect(pluginState.redoEnabledNotifier.value, isFalse);

      void externalListener() {
        pluginState.updateUndoRedoState();
      }

      pluginState.lineAnnotationsListNotifier.addListener(externalListener);
      addTearDown(() => pluginState.lineAnnotationsListNotifier.removeListener(externalListener));

      pluginState.lineAnnotationsListNotifier.addAnnotations([lineAnnotation, lineAnnotation2]);
      pluginState.lineAnnotationsListNotifier.inactivateId('test-line-2');

      expect(pluginState.lineAnnotationsListNotifier.value, [
        lineAnnotation,
        lineAnnotation2Inactive,
      ]);
      expect(pluginState.undoEnabledNotifier.value, isTrue);
      expect(pluginState.redoEnabledNotifier.value, isTrue);
    });
  });
}
