import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdf_annotations/pdf_annotations.dart';
import 'package:pdf_annotations/src/presentation/widgets/current_line_renderer.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:transparent_pointer/transparent_pointer.dart';

// --- Mocks ---
class MockPdfAnnotationsViewController extends Mock implements PdfAnnotationsViewController {}

class MockPdfDocument extends Mock implements PdfDocument {}

class MockPdfViewController extends Mock implements PdfViewerController {}

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
              startPage: 0,
              initialOffset: Offset.zero,
              initialAnnotationColour: Colors.red,
              initialFontSize: 14.0,
              initialFontFamily: 'Arial',
              pdfZoom: 1.0,
              pdfAnnotationsViewController: mockController,
            ),
          ),
        ),
      );
    }

    testWidgets('should assign controller properties on initialization', (tester) async {
      await pumpWidget(tester);

      verify(() => mockController.undo = captureAny()).called(1);
      verify(() => mockController.redo = captureAny()).called(1);
      verify(() => mockController.saveAnnotations = captureAny()).called(1);
      verify(() => mockController.setAnnotationColour = captureAny()).called(1);
      verify(() => mockController.setAnnotationQuality = captureAny()).called(1);
      verify(() => mockController.setLineMode = captureAny()).called(1);
      verify(() => mockController.setPosition = captureAny()).called(1);
      verify(() => mockController.getPosition = captureAny()).called(1);
      verify(() => mockController.getBakedPath = captureAny()).called(1);
      verify(() => mockController.setEditMode = captureAny()).called(1);
      verify(() => mockController.setPopInvoked = captureAny()).called(1);
      verify(() => mockController.setFontSize = captureAny()).called(1);
      verify(() => mockController.setFontFamily = captureAny()).called(1);
      verify(() => mockController.registerFonts = captureAny()).called(1);
    });

    testWidgets('should switch to draw mode and find CurrentLineRenderer', (tester) async {
      when(() => mockPdfViewController.goToPage(pageNumber: any(named: 'pageNumber'))).thenAnswer((_) async => {});
      when(
        () => mockPdfViewController.goToPosition(documentOffset: any(named: 'documentOffset')),
      ).thenAnswer((_) async => {});
      when(() => mockPdfViewController.currentZoom).thenReturn(1.0);

      await pumpWidget(tester);

      final pdfView = tester.widget<PdfViewer>(find.byType(PdfViewer));
      final mockDocument = MockPdfDocument();
      when(() => mockDocument.pages).thenReturn([]);
      pdfView.params.onViewerReady?.call(mockDocument, mockPdfViewController);
      await tester.pumpAndSettle();

      final setEditMode =
          verify(() => mockController.setEditMode = captureAny()).captured.single as void Function(EditMode);

      setEditMode(EditMode.draw);
      await tester.pump();

      expect(find.byType(CurrentLineRenderer), findsOneWidget);
    });

    testWidgets('should switch to pan mode and find TransparentPointer with correct intercept mode', (tester) async {
      when(() => mockPdfViewController.goToPage(pageNumber: any(named: 'pageNumber'))).thenAnswer((_) async => {});
      when(
        () => mockPdfViewController.goToPosition(documentOffset: any(named: 'documentOffset')),
      ).thenAnswer((_) async => {});
      when(() => mockPdfViewController.currentZoom).thenReturn(1.0);

      await pumpWidget(tester);

      // We need to trigger the layout so the TransparentPointer builds
      final pdfView = tester.widget<PdfViewer>(find.byType(PdfViewer));
      final mockDocument = MockPdfDocument();
      when(() => mockDocument.pages).thenReturn([]);
      pdfView.params.onViewerReady?.call(mockDocument, mockPdfViewController);
      await tester.pumpAndSettle();

      final setEditMode =
          verify(() => mockController.setEditMode = captureAny()).captured.single as void Function(EditMode);

      setEditMode(EditMode.pan);
      await tester.pump();

      // Find all TransparentPointers in the tree
      final transparentPointers = tester.widgetList<TransparentPointer>(find.byType(TransparentPointer));

      // At least one of them should have transparent=true (since there are multiple in the tree)
      bool foundTransparent = false;
      for (final p in transparentPointers) {
        if (p.transparent) foundTransparent = true;
      }
      expect(foundTransparent, true);
    });

    testWidgets('should show loading indicator when pop is invoked', (tester) async {
      when(() => mockPdfViewController.goToPage(pageNumber: any(named: 'pageNumber'))).thenAnswer((_) async => {});
      when(
        () => mockPdfViewController.goToPosition(documentOffset: any(named: 'documentOffset')),
      ).thenAnswer((_) async => {});
      when(() => mockPdfViewController.currentZoom).thenReturn(1.0);

      await pumpWidget(tester);

      final pdfView = tester.widget<PdfViewer>(find.byType(PdfViewer));
      final mockDocument = MockPdfDocument();
      when(() => mockDocument.pages).thenReturn([]);
      pdfView.params.onViewerReady?.call(mockDocument, mockPdfViewController);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);

      final setPopInvoked =
          verify(() => mockController.setPopInvoked = captureAny()).captured.single as void Function();

      setPopInvoked();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should notify undo availability change when annotation is added', (tester) async {
      // Setup mocks
      when(() => mockPdfViewController.goToPage(pageNumber: any(named: 'pageNumber'))).thenAnswer((_) async => {});
      when(
        () => mockPdfViewController.goToPosition(documentOffset: any(named: 'documentOffset')),
      ).thenAnswer((_) async => {});
      when(() => mockPdfViewController.currentZoom).thenReturn(1.0);

      // Verify callback is wired
      bool? isUndoAvailable;

      when(
        () => mockController.onUndoAvailabilityChanged,
      ).thenReturn((bool isAvailable) => isUndoAvailable = isAvailable);

      await pumpWidget(tester);

      final pdfView = tester.widget<PdfViewer>(find.byType(PdfViewer));
      final mockDocument = MockPdfDocument();
      when(() => mockDocument.pages).thenReturn([]);
      pdfView.params.onViewerReady?.call(mockDocument, mockPdfViewController);
      await tester.pumpAndSettle();

      // Capture setEditMode and switch to draw
      final setEditMode =
          verify(() => mockController.setEditMode = captureAny()).captured.single as void Function(EditMode);

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
