import 'package:flutter/material.dart';

import '../../domain/entities/line_annotation.dart';
import '../../utilities/constants.dart';
import '../../utilities/enums.dart';

class DrawingRenderer extends CustomPainter {
  final List<LineAnnotation> lineAnnotations;
  final QualityValue annotationQuality;
  final double opacity;
  final ({String id, String type}) latestUndo;
  final ({String id, String type}) latestRedo;

  DrawingRenderer({
    required this.lineAnnotations,
    required this.annotationQuality,
    this.opacity = 1.0,
    this.latestUndo = const (id: '', type: ''),
    this.latestRedo = const (id: '', type: ''),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clipRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(clipRect);
    var paint = Paint()
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    for (final lineAnnotation in lineAnnotations) {
      final line = lineAnnotation.line;
      if (line.isEmpty) continue;
      final annotationInherentOpacity = lineAnnotation.colour.a;
      final isLatestUndo = latestUndo.id == lineAnnotation.id && latestUndo.type == kLineAnnotation;
      final isLatestRedo =
          latestRedo.id == lineAnnotation.id &&
          latestRedo.type == kLineAnnotation &&
          lineAnnotation.isActive;
      if (lineAnnotation.isActive || isLatestUndo || isLatestRedo) {
        paint.color = (isLatestUndo)
            ? lineAnnotation.colour.withValues(alpha: opacity * annotationInherentOpacity)
            : (isLatestRedo)
            ? lineAnnotation.colour.withValues(
                alpha: annotationInherentOpacity - (opacity * annotationInherentOpacity),
              )
            : lineAnnotation.colour;
        paint.strokeWidth = lineAnnotation.width;

        final path = Path()..moveTo(line.first.dx, line.first.dy);
        if (annotationQuality == .low) {
          for (int i = 1; i < line.length; ++i) {
            path.lineTo(line[i].dx, line[i].dy);
          }
        } else {
          for (int i = 1; i < line.length - 1; ++i) {
            final p0 = line[i];
            final p1 = line[i + 1];
            path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
          }
        }

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingRenderer oldDelegate) {
    return oldDelegate.opacity != opacity || oldDelegate.lineAnnotations != lineAnnotations;
  }
}
