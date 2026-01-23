import 'package:flutter/material.dart';

import '../../utilities/enums.dart';
import 'all_lines_renderer.dart';
import 'all_texts_renderer.dart';
import 'current_text.dart';
import 'pan_layer.dart';

class AllOverlayWidgets extends StatelessWidget {
  final CurrentText currentText;
  final Widget currentLine;
  final PanLayer panLayer;
  final EditMode selectedEditMode;

  const AllOverlayWidgets({
    super.key,
    required this.currentText,
    required this.currentLine,
    required this.panLayer,
    required this.selectedEditMode,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [const AllLines(), const AllTexts()];

    switch (selectedEditMode) {
      case .text:
        widgets.add(panLayer);
        widgets.add(currentText);
        break;
      case .draw:
        widgets.add(panLayer);
        widgets.add(currentLine);
        break;
      case .pan:
        widgets.add(panLayer);
        break;
    }

    return Stack(children: widgets);
  }
}

class AllTexts extends StatelessWidget {
  const AllTexts({super.key});

  @override
  Widget build(BuildContext context) => const RepaintBoundary(
    child: SizedBox(width: .infinity, height: .infinity, child: AllTextsRenderer()),
  );
}

class AllLines extends StatelessWidget {
  const AllLines({super.key});

  @override
  Widget build(BuildContext context) => const RepaintBoundary(
    child: SizedBox(width: .infinity, height: .infinity, child: AllLinesRenderer()),
  );
}
