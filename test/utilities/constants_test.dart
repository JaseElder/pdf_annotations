import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:pdf_annotations/src/utilities/constants.dart';

void main() {
  group('Constants and Orientation Mapping', () {
    test('constants have expected configured values', () {
      expect(kAnnotationsAnimationDuration, 300);
      expect(kTextAnnotation, 'TextAnnotation');
      expect(kLineAnnotation, 'LineAnnotation');
      expect(kPdfSuffix, '.pdf');
      expect(kKeyboardToolbarHeight, 100.0);
      expect(kHighlighterOpacity, 0.5);
    });

    test('nativeToDeviceOrientationMap maps all orientation values', () {
      expect(
        nativeToDeviceOrientationMap[NativeDeviceOrientation.portraitUp],
        DeviceOrientation.portraitUp,
      );
      expect(
        nativeToDeviceOrientationMap[NativeDeviceOrientation.portraitDown],
        DeviceOrientation.portraitDown,
      );
      expect(
        nativeToDeviceOrientationMap[NativeDeviceOrientation.landscapeLeft],
        DeviceOrientation.landscapeLeft,
      );
      expect(
        nativeToDeviceOrientationMap[NativeDeviceOrientation.landscapeRight],
        DeviceOrientation.landscapeRight,
      );
      expect(
        nativeToDeviceOrientationMap[NativeDeviceOrientation.unknown],
        DeviceOrientation.portraitUp,
      );
    });
  });
}
