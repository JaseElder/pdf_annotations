import 'package:flutter/material.dart';
import '../utilities/gesture_recognizers.dart';

class PanLayer extends StatelessWidget {
  final Key gDKey;
  final Function(DragStartDetails) onDragStart;

  const PanLayer({required this.gDKey, required this.onDragStart, super.key});

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      key: gDKey,
      gestures: {
        AllowMultipleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<AllowMultipleGestureRecognizer>(
              () => AllowMultipleGestureRecognizer(),
              (AllowMultipleGestureRecognizer instance) {
                instance.onStart = onDragStart;
              },
            ),
      },
      behavior: .translucent,
    );
  }
}
