import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_annotations/src/data/repositories/json_annotations_repository_impl.dart';
import 'package:pdf_annotations/src/domain/entities/added_annotation.dart';
import 'package:pdf_annotations/src/domain/entities/line_annotation.dart';
import 'package:pdf_annotations/src/domain/entities/text_annotation.dart';
import 'package:pdf_annotations/src/utilities/enums.dart';

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
        LineAnnotation([const Offset(10, 20)], Colors.red, 2.0, true),
      ];
      final textAnnotations = [
        TextAnnotation('test', 'Roboto', 12, 12, const Offset(0, 0), Colors.black, true, '1'),
      ];
      const vpPosition = Offset.zero;
      const overlayWidthScaled = 200.0;
      const pdfPath = 'test.pdf';
      final addedAnnotations = [AddedAnnotation('text', '1')];

      final result = await repository.saveAnnotationsState(
        lineAnnotations: lineAnnotations,
        textAnnotations: textAnnotations,
        vpPosition: vpPosition,
        overlayWidthScaled: overlayWidthScaled,
        pdfPath: pdfPath,
        addedAnnotations: addedAnnotations,
      );

      expect(result, SaveStateResult.fileCreated);

      final loadedData = await repository.loadAnnotationsState(
        shortestSideEstimate: 200,
        pdfPath: pdfPath,
        overlayWidthScaled: overlayWidthScaled,
        vpPosition: vpPosition,
      );

      expect(loadedData, isNotNull);
      final (loadedLines, loadedTexts, loadedAdded) = loadedData!;
      expect(loadedLines.length, 1);
      expect(loadedTexts.length, 1);
      expect(loadedAdded.length, 1);
    });
  });
}
