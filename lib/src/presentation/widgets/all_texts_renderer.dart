import 'package:flutter/widgets.dart';

import '../../data/models/plugin_state.dart';
import '../../utilities/constants.dart';
import '../utilities/text_renderer.dart';

class AllTextsRenderer extends StatefulWidget {
  const AllTextsRenderer({super.key});

  @override
  State<AllTextsRenderer> createState() => _AllTextsRendererState();
}

class _AllTextsRendererState extends State<AllTextsRenderer> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final PluginState _pluginState;

  @override
  void initState() {
    super.initState();
    late Animation<double> animation;

    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));

    animation = Tween(begin: 1.0, end: 0.0).animate(_animationController)
      ..addListener(() => _pluginState.opacityValueNotifier.value = animation.value)
      ..addStatusListener((AnimationStatus status) {
        if (status == .completed) {
          _pluginState.lastUndoNotifier.value = (id: '', type: '');
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pluginState.lastUndoNotifier.addListener(_fadeLast);
    });
  }

  @override
  void dispose() {
    _pluginState.lastUndoNotifier.removeListener(_fadeLast);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pluginState = PluginStateProvider.of(context);

    return StreamBuilder(
      stream: _pluginState.textsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text(snapshot.error.toString());
        if (!snapshot.hasData) return Container();
        final annotations = snapshot.data!;
        if (annotations.isNotEmpty) {
          return ValueListenableBuilder(
            valueListenable: _pluginState.opacityValueNotifier,
            builder: (context, opacityValue, child) {
              return ValueListenableBuilder(
                valueListenable: _pluginState.lastUndoNotifier,
                builder: (context, lastUndoValue, child) {
                  return CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: TextRenderer(
                      textAnnotations: annotations,
                      opacity: opacityValue,
                      latestUndo: lastUndoValue,
                    ),
                  );
                },
              );
            },
          );
        }
        return Container();
      },
    );
  }

  void _fadeLast() {
    final undoLast = _pluginState.lastUndoNotifier.value;
    if (undoLast.id != '' && undoLast.type == kTextAnnotation) {
      _animationController.reset();
      _animationController.forward();
    }
  }
}
