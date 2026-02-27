import 'package:flutter/widgets.dart';

import '../../data/models/plugin_state.dart';
import '../../utilities/constants.dart';
import '../utilities/drawing_renderer.dart';

class AllLinesRenderer extends StatefulWidget {
  const AllLinesRenderer({super.key});

  @override
  State<AllLinesRenderer> createState() => _AllLinesRendererState();
}

class _AllLinesRendererState extends State<AllLinesRenderer> with SingleTickerProviderStateMixin {
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
          _pluginState.lastRedoNotifier.value = (id: '', type: '');
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pluginState.lastUndoNotifier.addListener(_fadeLastUndo);
      _pluginState.lastRedoNotifier.addListener(_fadeLastRedo);
    });
  }

  @override
  void dispose() {
    _pluginState.lastUndoNotifier.removeListener(_fadeLastUndo);
    _pluginState.lastRedoNotifier.removeListener(_fadeLastRedo);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pluginState = PluginStateProvider.of(context);
    return StreamBuilder(
      stream: _pluginState.linesStream,
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
                  return ValueListenableBuilder(
                    valueListenable: _pluginState.lastRedoNotifier,
                    builder: (context, lastRedoValue, child) {
                      return CustomPaint(
                        isComplex: true,
                        willChange: true,
                        painter: DrawingRenderer(
                          lineAnnotations: annotations,
                          annotationQuality: _pluginState.annotationQualityNotifier.value,
                          opacity: opacityValue,
                          latestUndo: lastUndoValue,
                          latestRedo: lastRedoValue,
                        ),
                      );
                    },
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

  void _fadeLastUndo() {
    final undoLast = _pluginState.lastUndoNotifier.value;
    if (undoLast.id != '' && undoLast.type == kLineAnnotation) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _fadeLastRedo() {
    final redoLast = _pluginState.lastRedoNotifier.value;
    if (redoLast.id != '' && redoLast.type == kLineAnnotation) {
      _animationController.reset();
      _animationController.forward();
    }
  }
}
