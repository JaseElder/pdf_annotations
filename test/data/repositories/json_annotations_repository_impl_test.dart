import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/repositories/json_annotations_repository_impl.dart';
import 'package:pdf_annotations/src/domain/entities/added_annotation.dart';
import 'package:pdf_annotations/src/domain/entities/line_annotation.dart';
import 'package:pdf_annotations/src/domain/entities/text_annotation.dart';
import 'package:pdf_annotations/src/utilities/enums.dart';
import 'package:pdf_annotations/src/utilities/errors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JsonAnnotationsRepositoryImpl', () {
    late JsonAnnotationsRepositoryImpl repository;
    late Directory tempDir;

    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    const orientationChannel = MethodChannel('native_device_orientation');

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      repository = JsonAnnotationsRepositoryImpl(savedAnnotationsJsonSuffix: '_test.json');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        pathChannel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path;
          }
          return null;
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        orientationChannel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getOrientation') {
            return 'portraitUp';
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        pathChannel,
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        orientationChannel,
        null,
      );
      tempDir.deleteSync(recursive: true);
    });

    test('should save and load annotations', () async {
      final lineAnnotations = [
        LineAnnotation([const Offset(10, 20)], Colors.red, 2.0, true, 'line1'),
      ];
      final textAnnotations = [
        TextAnnotation('test', 'Roboto', 12, 12, const Offset(0, 0), Colors.black, true, 'text1'),
      ];
      const vpPosition = Offset.zero;
      const overlayWidthScaled = 200.0;
      const pdfPath = 'test.pdf';
      final addedAnnotations = [AddedAnnotation('line', 'line1'), AddedAnnotation('text', 'text1')];

      final result = await repository.saveAnnotationsState(
        lineAnnotations: lineAnnotations,
        textAnnotations: textAnnotations,
        vpPosition: vpPosition,
        overlayWidthScaled: overlayWidthScaled,
        pdfPath: pdfPath,
        addedAnnotations: addedAnnotations,
        annotationQuality: .low,
      );

      expect(result, isA<Success<SaveStateResult>>());
      expect((result as Success).data, SaveStateResult.fileCreated);

      final loadResult = await repository.loadAnnotationsState(
        shortestSideEstimate: 200,
        pdfPath: pdfPath,
        overlayWidthScaled: overlayWidthScaled,
        vpPosition: vpPosition,
      );

      expect(loadResult, isA<Success>());

      final (loadedLines, loadedTexts, loadedAdded, annotationQuality) = (loadResult as Success).data;
      expect(loadedLines.length, 1);
      expect(loadedTexts.length, 1);
      expect(loadedAdded.length, 2);
      expect(annotationQuality, QualityValue.low);
    });

    test('should save annotations and save again when annotations change', () async {
      final lineAnnotations = [
        LineAnnotation([const Offset(10, 20)], Colors.red, 2.0, true, 'line1'),
      ];
      final textAnnotations = [
        TextAnnotation('test', 'Roboto', 12, 12, const Offset(0, 0), Colors.black, true, 'text1'),
      ];
      const vpPosition = Offset.zero;
      const overlayWidthScaled = 200.0;
      const pdfPath = 'test.pdf';
      final addedAnnotations = [AddedAnnotation('line', 'line1'), AddedAnnotation('text', 'text1')];

      final result = await repository.saveAnnotationsState(
        lineAnnotations: lineAnnotations,
        textAnnotations: textAnnotations,
        vpPosition: vpPosition,
        overlayWidthScaled: overlayWidthScaled,
        pdfPath: pdfPath,
        addedAnnotations: addedAnnotations,
        annotationQuality: .low,
      );

      expect(result, isA<Success>());
      expect((result as Success).data, SaveStateResult.fileCreated);

      final result2 = await repository.saveAnnotationsState(
        lineAnnotations: lineAnnotations,
        textAnnotations: textAnnotations,
        vpPosition: vpPosition,
        overlayWidthScaled: overlayWidthScaled,
        pdfPath: pdfPath,
        addedAnnotations: addedAnnotations,
        annotationQuality: .low,
      );

      expect(result2, isA<Success>());
      expect((result2 as Success).data, SaveStateResult.noChange);

      final loadResult = await repository.loadAnnotationsState(
        shortestSideEstimate: 200,
        pdfPath: pdfPath,
        overlayWidthScaled: overlayWidthScaled,
        vpPosition: vpPosition,
      );

      expect(loadResult, isA<Success>());

      final (loadedLines, loadedTexts, loadedAdded, annotationQuality) = (loadResult as Success).data;
      expect(loadedLines.length, 1);
      expect(loadedTexts.length, 1);
      expect(loadedAdded.length, 2);
      expect(annotationQuality, QualityValue.low);
    });

    test('should return Failure (or empty success) when file does not exist', () async {
      const pdfPath = 'non_existent.pdf';

      final loadResult = await repository.loadAnnotationsState(
        shortestSideEstimate: 200,
        pdfPath: pdfPath,
        overlayWidthScaled: 100,
        vpPosition: Offset.zero,
      );

      expect(loadResult, isA<Success>());
      final (loadedLines, loadedTexts, loadedAdded, annotationQuality) = (loadResult as Success).data;
      expect(loadedLines.length, 0);
      expect(loadedTexts.length, 0);
      expect(loadedAdded.length, 0);
      expect(annotationQuality, QualityValue.high);
    });

    test('should return Failure when JSON is corrupted', () async {
      const pdfPath = 'corrupt.pdf';
      // Manually create a corrupt file in the temp dir
      final file = File('${tempDir.path}/corrupt_test.json');
      await file.writeAsString('{ invalid json: [ }');

      final loadResult = await repository.loadAnnotationsState(
        shortestSideEstimate: 200,
        pdfPath: pdfPath,
        overlayWidthScaled: 100,
        vpPosition: Offset.zero,
      );

      expect(loadResult, isA<Failure>());
      final failure = loadResult as Failure;
      expect(failure.error, isA<FormatException>());
    });

    test('should save all inactive annotations thus not loading', () async {
      final lineAnnotations = [
        LineAnnotation([const Offset(10, 20)], Colors.red, 2.0, false, 'line1'),
      ];
      final textAnnotations = [
        TextAnnotation('test', 'Roboto', 12, 12, const Offset(0, 0), Colors.black, false, 'text1'),
      ];
      const vpPosition = Offset.zero;
      const overlayWidthScaled = 200.0;
      const pdfPath = 'test.pdf';
      final addedAnnotations = [AddedAnnotation('line', 'line1'), AddedAnnotation('text', 'text1')];

      final result = await repository.saveAnnotationsState(
        lineAnnotations: lineAnnotations,
        textAnnotations: textAnnotations,
        vpPosition: vpPosition,
        overlayWidthScaled: overlayWidthScaled,
        pdfPath: pdfPath,
        addedAnnotations: addedAnnotations,
        annotationQuality: .low,
      );

      expect(result, isA<Success>());
      expect((result as Success).data, SaveStateResult.noChange);

      final loadResult = await repository.loadAnnotationsState(
        shortestSideEstimate: 200,
        pdfPath: pdfPath,
        overlayWidthScaled: overlayWidthScaled,
        vpPosition: vpPosition,
      );

      expect(loadResult, isA<Success>());
      final (loadedLines, loadedTexts, loadedAdded, annotationQuality) = (loadResult as Success).data;
      expect(loadedLines.length, 0);
      expect(loadedTexts.length, 0);
      expect(loadedAdded.length, 0);
      expect(annotationQuality, QualityValue.high);
    });
  });
}
