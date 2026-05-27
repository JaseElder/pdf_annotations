import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

const int kAnnotationsAnimationDuration = 300;
const String kTextAnnotation = 'TextAnnotation';
const String kLineAnnotation = 'LineAnnotation';
const String kPdfSuffix = '.pdf';
const double kKeyboardToolbarHeight = 100.0;
const double kHighlighterOpacity = 0.5;

final Map<NativeDeviceOrientation, DeviceOrientation> nativeToDeviceOrientationMap = {
  NativeDeviceOrientation.portraitUp: DeviceOrientation.portraitUp,
  NativeDeviceOrientation.portraitDown: DeviceOrientation.portraitDown,
  NativeDeviceOrientation.landscapeLeft: DeviceOrientation.landscapeLeft,
  NativeDeviceOrientation.landscapeRight: DeviceOrientation.landscapeRight,
  NativeDeviceOrientation.unknown: DeviceOrientation.portraitUp,
};
