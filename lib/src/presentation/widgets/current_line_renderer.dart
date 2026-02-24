import 'package:flutter/widgets.dart';

import '../../data/models/plugin_state.dart';
import '../utilities/drawing_renderer.dart';

class CurrentLineRenderer extends StatelessWidget {
  const CurrentLineRenderer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = PluginStateProvider.of(context);
    final qualityValue = provider.annotationQualityNotifier.value;

    return StreamBuilder(
      stream: provider.currentLineStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text(snapshot.error.toString());
        if (!snapshot.hasData) return Container();
        final annotation = snapshot.data!;

        return CustomPaint(
          isComplex: true,
          willChange: true,
          painter: DrawingRenderer(lineAnnotations: [annotation], annotationQuality: qualityValue),
        );
      },
    );
  }
}
