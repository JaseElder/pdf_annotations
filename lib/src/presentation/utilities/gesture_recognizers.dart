import 'package:flutter/gestures.dart';

class AllowMultipleGestureRecognizer extends PanGestureRecognizer {
  LongPressGestureRecognizer? _longPressRecognizer;
  DoubleTapGestureRecognizer? _doubleTapRecognizer;

  AllowMultipleGestureRecognizer() {
    _longPressRecognizer = LongPressGestureRecognizer()
      ..onLongPressStart = (details) {
        resolve(.accepted);
        if (onStart != null) {
          onStart!(DragStartDetails(globalPosition: details.globalPosition, localPosition: details.localPosition));
        }
      };
    _doubleTapRecognizer = DoubleTapGestureRecognizer()..onDoubleTap = () {};
  }

  @override
  void addPointer(PointerDownEvent event) {
    super.addPointer(event);
    _longPressRecognizer?.addPointer(event);
    _doubleTapRecognizer?.addPointer(event);
  }

  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }

  @override
  void dispose() {
    _longPressRecognizer?.dispose();
    _doubleTapRecognizer?.dispose();
    super.dispose();
  }
}
