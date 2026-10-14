import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/presentation/widgets/pdf_doc_view.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  group('PdfDocView tests', () {
    testWidgets('displays PdfViewer when pdfPath is provided', (WidgetTester tester) async {
      final controller = PdfDocViewController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfDocView(
              pdfDocViewController: controller,
              pdfPath: 'test_file.pdf',
              defaultPage: 0,
              onRender: (pages) {},
            ),
          ),
        ),
      );

      // Verify the PdfViewer is mounted
      expect(find.byType(PdfViewer), findsOneWidget);
      expect(find.text('No file'), findsNothing);
    });

    testWidgets('displays No file text when pdfPath is empty', (WidgetTester tester) async {
      final controller = PdfDocViewController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfDocView(
              pdfDocViewController: controller,
              pdfPath: '',
              defaultPage: 0,
              onRender: (pages) {},
            ),
          ),
        ),
      );

      // Verify the fallback text is shown
      expect(find.byType(PdfViewer), findsNothing);
      expect(find.text('No file'), findsOneWidget);
    });

    testWidgets('calls onPageChanged when PDF page changes', (WidgetTester tester) async {
      final controller = PdfDocViewController();
      int? reportedPage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfDocView(
              pdfDocViewController: controller,
              pdfPath: 'test_file.pdf',
              defaultPage: 0,
              onRender: (pages) {},
              onPageChanged: (page) {
                reportedPage = page;
              },
            ),
          ),
        ),
      );

      // Manually trigger the callback on the underlying PdfViewer to simulate native behavior
      final pdfView = tester.widget<PdfViewer>(find.byType(PdfViewer));
      if (pdfView.params.onPageChanged != null) {
        pdfView.params.onPageChanged!(5);
      }

      expect(reportedPage, equals(5));
    });
  });
}
