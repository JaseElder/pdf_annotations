import 'package:flutter/material.dart';

import '../../domain/entities/text_annotation.dart';
import '../../utilities/constants.dart';

class TextRenderer extends CustomPainter {
  final List<TextAnnotation?> textAnnotations;
  final double opacity;
  final ({String id, String type}) latestUndo;

  TextRenderer({required this.textAnnotations, required this.opacity, required this.latestUndo});

  @override
  void paint(Canvas canvas, Size size) {
    final clipRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(clipRect);
    for (int j = 0; j < textAnnotations.length; j++) {
      final textAnnotation = textAnnotations[j];
      final isLatestUndo =
          latestUndo.id == textAnnotation?.id && latestUndo.type == kTextAnnotation;
      if (textAnnotation!.isActive || isLatestUndo) {
        var textSpan = TextSpan(
          text: textAnnotation.text,
          style: TextStyle(
            color: (isLatestUndo)
                ? textAnnotation.colour.withValues(alpha: opacity)
                : textAnnotation.colour,
            fontFamily: textAnnotation.fontFamily,
            fontWeight: .w600,
            fontSize: textAnnotation.renderedFontSize,
          ),
        );

        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout(minWidth: 0, maxWidth: size.width);
        final offset = textAnnotation.coordinate;
        textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(TextRenderer oldDelegate) {
    return oldDelegate.opacity != opacity || oldDelegate.textAnnotations != textAnnotations;
  }
}
