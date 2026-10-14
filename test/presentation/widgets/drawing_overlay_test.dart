import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/plugin_state.dart';
import 'package:pdf_annotations/src/presentation/widgets/drawing_overlay.dart';
import 'package:pdf_annotations/src/presentation/widgets/pan_layer.dart';
import 'package:pdf_annotations/src/presentation/widgets/current_line_renderer.dart';
import 'package:pdf_annotations/src/presentation/widgets/current_text.dart';
import 'package:pdf_annotations/src/utilities/enums.dart';

void main() {
  group('DrawingOverlay Mega Tests', () {
    late PluginState state;
    late DrawingOverlayController overlayController;

    setUp(() {
      state = PluginState(
        savedAnnotationsJsonSuffix: 'test',
        initialOffset: Offset.zero,
        initialAnnotationColour: Colors.red,
        draggingTextFieldBackgroundColour: Colors.blue,
        initialFontSize: 14.0,
        initialFontFamily: 'Arial',
      );
      overlayController = DrawingOverlayController();
    });

    tearDown(() {
      state.dispose();
      overlayController.dispose();
    });

    Future<void> pumpOverlay(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginStateProvider(
              state,
              child: DrawingOverlay(
                drawingOverlayController: overlayController,
                pdfPath: 'fake.pdf',
                // onInsertionPointModified: (height) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Full text entry lifecycle (Tap, Type, Finalize, Undo, Redo)', (WidgetTester tester) async {
      await pumpOverlay(tester);

      // Switch to text mode
      state.editMode = EditMode.text;
      await tester.pumpAndSettle();

      final currentTextFinder = find.byType(CurrentText);
      expect(currentTextFinder, findsOneWidget);

      // Tap to place cursor
      await tester.tap(currentTextFinder);
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'Hello Coverage');
      await tester.pumpAndSettle();

      // Finalize the text by switching modes
      state.editMode = EditMode.pan;
      await tester.pumpAndSettle();

      expect(state.textAnnotationsListNotifier.value.length, 1);
      final textAnnotation = state.textAnnotationsListNotifier.value.first;
      expect(textAnnotation.text, 'Hello Coverage');
      expect(textAnnotation.isActive, isTrue);

      // Call Undo
      await overlayController.undo();
      await tester.pumpAndSettle();
      expect(state.textAnnotationsListNotifier.value.first.isActive, isFalse);

      // Call Redo
      await overlayController.redo();
      await tester.pumpAndSettle();
      expect(state.textAnnotationsListNotifier.value.first.isActive, isTrue);
    });

    testWidgets('Full line drawing lifecycle (Draw, Undo, Redo)', (WidgetTester tester) async {
      await pumpOverlay(tester);

      state.editMode = EditMode.draw;
      await tester.pumpAndSettle();

      final currentLineFinder = find.byType(CurrentLineRenderer);

      final gesture = await tester.startGesture(tester.getCenter(currentLineFinder));
      await gesture.moveBy(const Offset(50, 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(state.lineAnnotationsListNotifier.value.length, 1);
      expect(state.lineAnnotationsListNotifier.value.first.isActive, isTrue);

      await overlayController.undo();
      await tester.pumpAndSettle();
      expect(state.lineAnnotationsListNotifier.value.first.isActive, isFalse);

      await overlayController.redo();
      await tester.pumpAndSettle();
      expect(state.lineAnnotationsListNotifier.value.first.isActive, isTrue);
    });

    testWidgets('Panning shifts committed annotations correctly', (WidgetTester tester) async {
      await pumpOverlay(tester);

      state.editMode = EditMode.draw;
      await tester.pumpAndSettle();
      final currentLineFinder = find.byType(CurrentLineRenderer);
      final gesture = await tester.startGesture(tester.getCenter(currentLineFinder));
      await gesture.moveBy(const Offset(50, 50));
      await gesture.up();
      await tester.pumpAndSettle();

      state.editMode = EditMode.text;
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CurrentText));
      await tester.enterText(find.byType(TextField), 'Test Text');

      state.editMode = EditMode.pan;
      await tester.pumpAndSettle();

      expect(state.lineAnnotationsListNotifier.value, isNotEmpty);
      expect(state.textAnnotationsListNotifier.value, isNotEmpty);

      // Panning offset shift
      state.pdfOffsetNotifier.value = const Offset(0, -100);
      await tester.pumpAndSettle();

      expect(find.byType(PanLayer), findsOneWidget);
    });

    testWidgets('Keyboard shift animations run up and down', (WidgetTester tester) async {
      await pumpOverlay(tester);

      state.editMode = EditMode.draw;
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(find.byType(CurrentLineRenderer)));
      await gesture.moveBy(const Offset(50, 50));
      await gesture.up();

      state.editMode = EditMode.text;
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CurrentText));
      await tester.enterText(find.byType(TextField), 'Test Text');
      state.editMode = EditMode.pan;
      await tester.pumpAndSettle();

      state.editMode = EditMode.text;
      await tester.pumpAndSettle();
      state.textInsertionPointNotifier.setAbsolute(const Offset(0, 1900));

      state.keyboardHeightNotifier.value = 500.0;
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      state.keyboardHeightNotifier.value = 0.0;
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(DrawingOverlay), findsOneWidget);
    });

    testWidgets('Notifier listeners respond to external state changes', (WidgetTester tester) async {
      await pumpOverlay(tester);

      state.annotationColourNotifier.value = Colors.green;
      await tester.pumpAndSettle();

      state.lineModeNotifier.value = LineMode.highlighter;
      await tester.pumpAndSettle();

      state.textInsertionPointNotifier.value = const Offset(10, 10);
      await tester.pumpAndSettle();

      state.currentLineAnnotationNotifier.addPoint(const Offset(1, 1));
      await tester.pumpAndSettle();

      expect(find.byType(DrawingOverlay), findsOneWidget);
    });
  });
}
