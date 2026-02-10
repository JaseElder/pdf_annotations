// test/presentation/widgets/pdf_annotations_view_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdf_annotations/pdf_annotations.dart';
import 'package:pdf_annotations/src/presentation/widgets/current_line_renderer.dart';
import 'package:pdf_annotations/src/presentation/widgets/drawing_overlay.dart';
import 'package:transparent_pointer/transparent_pointer.dart';

// --- Mocks ---
class MockPdfAnnotationsViewController extends Mock implements PdfAnnotationsViewController {}

class MockPdfViewController extends Mock implements PDFViewController {}

void main() {
  group('PdfAnnotationsView Widget Tests', () {
    late PdfAnnotationsViewController mockController;
    late MockPdfViewController mockPdfViewController;

    setUp(() {
      mockController = MockPdfAnnotationsViewController();
      mockPdfViewController = MockPdfViewController();

      registerFallbackValue(Offset.zero);
      registerFallbackValue(const Color(0xFF000000));
      registerFallbackValue(EditMode.pan);
      registerFallbackValue(LineMode.highlighter);
      registerFallbackValue(QualityValue.high);
      registerFallbackValue(<PdfFont>[]);
    });

    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfAnnotationsView(
              pdfPath: 'test.pdf',
              pdfDefaultScale: 1.0,
              startPage: 0,
              initialOffset: Offset.zero,
              initialAnnotationColour: Colors.red,
              initialFontSize: 14.0,
              initialFontFamily: 'Arial',
              pdfZoom: 1.0,
              pdfAnnotationsViewController: mockController,
              onZoomUpdate: (_) {},
              onDefaultScaleUpdate: (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('should show progress indicator initially, then hide it after render', (
      tester,
    ) async {
      // Stub the PDFViewController methods. Use a return of "true" for all
      // commands that return Future<bool> to satisfy the type system.

      when(() => mockPdfViewController.setPage(any())).thenAnswer((_) async => true);
      when(
        () => mockPdfViewController.setZoomLimits(any(), any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockPdfViewController.setPosition(any())).thenAnswer((_) async => true);
      when(() => mockPdfViewController.setScale(any())).thenAnswer((_) async => true);
      // getScale returns Future<double>
      when(() => mockPdfViewController.getScale()).thenAnswer((_) async => 1.0);

      await pumpWidget(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(DrawingOverlay), findsNothing);

      final pdfViewFinder = find.byType(PDFView);
      expect(pdfViewFinder, findsOneWidget);

      final pdfView = tester.widget<PDFView>(pdfViewFinder);

      if (pdfView.onViewCreated != null) {
        pdfView.onViewCreated!(mockPdfViewController);
      }

      if (pdfView.onRender != null) {
        pdfView.onRender!(10);
      }

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(DrawingOverlay), findsOneWidget);

      verify(() => mockPdfViewController.setZoomLimits(1.0, 1.0, 1.0)).called(1);
      verify(() => mockPdfViewController.setPosition(any())).called(1);
      verify(() => mockPdfViewController.setScale(1.0)).called(1);
    });

    testWidgets('should wire up all methods to the PdfAnnotationsViewController', (tester) async {
      when(() => mockPdfViewController.setPage(any())).thenAnswer((_) async => true);
      when(
        () => mockPdfViewController.setZoomLimits(any(), any(), any()),
      ).thenAnswer((_) async => true); // Corrected to return true
      when(() => mockPdfViewController.setPosition(any())).thenAnswer((_) async => true);
      when(() => mockPdfViewController.setScale(any())).thenAnswer((_) async => true);
      when(() => mockPdfViewController.getScale()).thenAnswer((_) async => 1.0);

      await pumpWidget(tester);

      final pdfView = tester.widget<PDFView>(find.byType(PDFView));
      pdfView.onViewCreated!(mockPdfViewController);
      pdfView.onRender!(10);

      await tester.pumpAndSettle();

      expect(
        verify(() => mockController.saveAnnotations = captureAny()).captured.single,
        isA<Future<bool> Function()>(),
      );
      expect(
        verify(() => mockController.undo = captureAny()).captured.single,
        isA<Future<void> Function()>(),
      );
      expect(
        verify(() => mockController.redo = captureAny()).captured.single,
        isA<Future<void> Function()>(),
      );
      expect(
        verify(() => mockController.setAnnotationColour = captureAny()).captured.single,
        isA<void Function(Color)>(),
      );
      expect(
        verify(() => mockController.setAnnotationQuality = captureAny()).captured.single,
        isA<void Function(QualityValue)>(),
      );
      expect(
        verify(() => mockController.setLineMode = captureAny()).captured.single,
        isA<void Function(LineMode)>(),
      );
      expect(
        verify(() => mockController.setPosition = captureAny()).captured.single,
        isA<void Function(Offset)>(),
      );
      expect(
        verify(() => mockController.getPosition = captureAny()).captured.single,
        isA<Offset Function()>(),
      );
      expect(
        verify(() => mockController.setEditMode = captureAny()).captured.single,
        isA<void Function(EditMode)>(),
      );
      expect(
        verify(() => mockController.setFontSize = captureAny()).captured.single,
        isA<void Function(double)>(),
      );
      expect(
        verify(() => mockController.setFontFamily = captureAny()).captured.single,
        isA<void Function(String)>(),
      );
      expect(
        verify(() => mockController.setKeyboardHeight = captureAny()).captured.single,
        isA<void Function(double)>(),
      );
      expect(
        verify(() => mockController.keyboardDismissed = captureAny()).captured.single,
        isA<void Function()>(),
      );
      expect(
        verify(() => mockController.setPopInvoked = captureAny()).captured.single,
        isA<void Function()>(),
      );
      expect(
        verify(() => mockController.registerFonts = captureAny()).captured.single,
        isA<Future<bool> Function(List<PdfFont>)>(),
      );
    });

    testWidgets('should propagate callbacks from PDFView', (tester) async {
      // Setup mocks
      when(() => mockPdfViewController.setPage(any())).thenAnswer((_) async => true);
      when(
        () => mockPdfViewController.setZoomLimits(any(), any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockPdfViewController.setPosition(any())).thenAnswer((_) async => true);
      when(() => mockPdfViewController.setScale(any())).thenAnswer((_) async => true);
      when(() => mockPdfViewController.getScale()).thenAnswer((_) async => 1.0);

      int? lastPage;
      dynamic lastError;

      // Build widget with callbacks
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfAnnotationsView(
              pdfPath: 'test.pdf',
              pdfDefaultScale: 1.0,
              startPage: 0,
              initialOffset: Offset.zero,
              initialAnnotationColour: Colors.red,
              initialFontSize: 14.0,
              initialFontFamily: 'Arial',
              pdfZoom: 1.0,
              pdfAnnotationsViewController: mockController,
              onZoomUpdate: (_) {},
              onDefaultScaleUpdate: (_) {},
              onPageChanged: (page) => lastPage = page,
              onError: (error) => lastError = error,
            ),
          ),
        ),
      );

      // Find inner PDFView
      final pdfView = tester.widget<PDFView>(find.byType(PDFView));

      // Simulate view creation and render to settle the widget
      if (pdfView.onViewCreated != null) {
        pdfView.onViewCreated!(mockPdfViewController);
      }
      if (pdfView.onRender != null) {
        pdfView.onRender!(10);
      }
      await tester.pumpAndSettle();

      // Simulate Page Change
      if (pdfView.onPageChanged != null) {
        pdfView.onPageChanged!(5, 10);
      }
      expect(lastPage, equals(5));

      // Simulate Error
      if (pdfView.onError != null) {
        pdfView.onError!('Simulated Error');
      }
      expect(lastError, equals('Simulated Error'));
    });

    testWidgets('should update TransparentPointer when switching edit mode', (tester) async {
      // Setup mocks
      when(() => mockPdfViewController.setPage(any())).thenAnswer((_) async => true);
      when(
        () => mockPdfViewController.setZoomLimits(any(), any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockPdfViewController.setPosition(any())).thenAnswer((_) async => true);
      when(() => mockPdfViewController.setScale(any())).thenAnswer((_) async => true);
      when(() => mockPdfViewController.getScale()).thenAnswer((_) async => 1.0);

      await pumpWidget(tester);

      final pdfView = tester.widget<PDFView>(find.byType(PDFView));
      pdfView.onViewCreated!(mockPdfViewController);
      pdfView.onRender!(10);
      await tester.pumpAndSettle();

      // Capture the setEditMode function
      final setEditMode =
          verify(() => mockController.setEditMode = captureAny()).captured.single
              as void Function(EditMode);

      // Initially pan mode might be set or default text/draw.
      // Let's set it to 'pan' and check transparency (should be transparent)
      setEditMode(EditMode.pan);
      await tester.pump();

      // Find TransparentPointer
      final transparentPointerFinder = find
          .descendant(of: find.byType(Visibility), matching: find.byType(TransparentPointer))
          .first; // .first because Visibility might hide others, but here structure is fixed

      TransparentPointer widget = tester.widget<TransparentPointer>(transparentPointerFinder);
      // In Pan mode, transparent should be true (allowing touches to pass to PDF)
      expect(widget.transparent, isTrue);

      // Set to 'draw' mode
      setEditMode(EditMode.draw);
      await tester.pump();

      widget = tester.widget<TransparentPointer>(transparentPointerFinder);
      // In Draw mode, transparent should be false (intercepting touches for drawing)
      // Note: On Android Platform.isAndroid is true so it might be always true in code,
      // but test environment is likely Linux/Mac, so Platform.isAndroid is false.
      expect(widget.transparent, isFalse);
    });

    testWidgets('should show loading indicator when pop is invoked', (tester) async {
      // Setup mocks
      when(() => mockPdfViewController.setPage(any())).thenAnswer((_) async => true);
      when(
        () => mockPdfViewController.setZoomLimits(any(), any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockPdfViewController.setPosition(any())).thenAnswer((_) async => true);
      when(() => mockPdfViewController.setScale(any())).thenAnswer((_) async => true);
      when(() => mockPdfViewController.getScale()).thenAnswer((_) async => 1.0);

      await pumpWidget(tester);

      final pdfView = tester.widget<PDFView>(find.byType(PDFView));
      pdfView.onViewCreated!(mockPdfViewController);
      pdfView.onRender!(10);
      await tester.pumpAndSettle();

      // Initial state: No progress indicator (it was hidden after render)
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Capture and invoke setPopInvoked
      final setPopInvoked =
          verify(() => mockController.setPopInvoked = captureAny()).captured.single
              as void Function();

      setPopInvoked();
      await tester.pump();

      // Verify progress indicator is back
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should notify undo availability change when annotation is added', (tester) async {
      // Setup mocks
      when(() => mockPdfViewController.setPage(any())).thenAnswer((_) async => true);
      when(
        () => mockPdfViewController.setZoomLimits(any(), any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockPdfViewController.setPosition(any())).thenAnswer((_) async => true);
      when(() => mockPdfViewController.setScale(any())).thenAnswer((_) async => true);
      when(() => mockPdfViewController.getScale()).thenAnswer((_) async => 1.0);

      // Verify callback is wired
      bool? isUndoAvailable;

      when(
        () => mockController.onUndoAvailabilityChanged,
      ).thenReturn((bool isAvailable) => isUndoAvailable = isAvailable);

      await pumpWidget(tester);

      final pdfView = tester.widget<PDFView>(find.byType(PDFView));
      pdfView.onViewCreated!(mockPdfViewController);
      pdfView.onRender!(10);
      await tester.pumpAndSettle();

      // Capture setEditMode and switch to draw
      final setEditMode =
          verify(() => mockController.setEditMode = captureAny()).captured.single
              as void Function(EditMode);

      setEditMode(EditMode.draw);
      await tester.pump();

      // Find the CurrentLineRenderer which has the GestureDetector
      final drawingSurfaceFinder = find.byType(CurrentLineRenderer);
      expect(
        drawingSurfaceFinder,
        findsOneWidget,
        reason: "Should find drawing surface in draw mode",
      );

      // Perform a drag gesture to draw a line
      // Note: The GestureDetector uses onScaleStart, onScaleUpdate, onScaleEnd.
      // startGesture combined with down/move/up events can simulate this.
      final gesture = await tester.startGesture(tester.getCenter(drawingSurfaceFinder));
      await gesture.moveBy(const Offset(100, 100));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300)); // Wait for DoubleTap timer to expire

      // After drawing, undo should be available
      expect(isUndoAvailable, isTrue);
    });
  });
}
