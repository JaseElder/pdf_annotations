import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/models/pdf_font.dart';
import 'package:pdf_annotations/src/data/repositories/pdf_annotations_repository_impl.dart';
import 'package:pdf_annotations/src/domain/entities/line_annotation.dart';
import 'package:pdf_annotations/src/domain/entities/text_annotation.dart';
import 'package:pdf_annotations/src/utilities/errors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfAnnotationsRepositoryImpl', () {
    late PdfAnnotationsRepositoryImpl repository;

    setUp(() {
      repository = PdfAnnotationsRepositoryImpl();
      const codec = StandardMessageCodec();
      const channelPrefix = 'dev.flutter.pigeon.pdf_annotations.PdfAnnotationsApi';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        '$channelPrefix.addAnnotations',
        (ByteData? message) async {
          return codec.encodeMessage(<Object?>[true]);
        },
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        '$channelPrefix.undoAnnotation',
        (ByteData? message) async {
          return codec.encodeMessage(<Object?>[true]);
        },
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        '$channelPrefix.registerFonts',
        (ByteData? message) async {
          return codec.encodeMessage(<Object?>[true]);
        },
      );
    });

    tearDown(() {
      const channelPrefix = 'dev.flutter.pigeon.pdf_annotations.PdfAnnotationsApi';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        '$channelPrefix.addAnnotations',
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        '$channelPrefix.undoAnnotation',
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        '$channelPrefix.registerFonts',
        null,
      );
    });

    test('should add annotations and return true on success', () async {
      final lineAnnotations = [
        LineAnnotation([const Offset(10, 20)], Colors.red, 2.0, true),
      ];
      final textAnnotations = [
        TextAnnotation('test', 'Roboto', 12.0, 12.0, const Offset(0, 0), Colors.black, true, '1'),
      ];
      final fonts = [PdfFont(family: 'Roboto', fileName: 'Roboto.ttf')];

      final result = await repository.addAnnotations(
        fileName: 'test.pdf',
        lineAnnotations: lineAnnotations,
        textAnnotations: textAnnotations,
        fonts: fonts,
        annotationQuality: .high,
        pdfPageDims: const Offset(200, 300),
        totalPdfLength: 300,
        viewportOffset: Offset.zero,
        overlayScale: 1.0,
      );

      expect(result, isA<Success<bool>>());
      expect((result as Success).data, true);
    });
  });
}
