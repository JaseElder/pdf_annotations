import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models/plugin_state.dart';

class CurrentText extends StatefulWidget {
  final TextEditingController textFieldController;
  final double scale;
  final Function(TapUpDetails) onTapUp;
  final Function(String) onTapOutside;
  final Function() onFirstCharacterEntry;

  const CurrentText({
    required this.textFieldController,
    required this.scale,
    required this.onTapUp,
    required this.onTapOutside,
    required this.onFirstCharacterEntry,
    super.key,
  });

  @override
  State<CurrentText> createState() => _CurrentTextState();
}

class _CurrentTextState extends State<CurrentText> {
  InputDecoration _decoration = const InputDecoration(isCollapsed: true, border: .none);

  @override
  Widget build(BuildContext context) {
    final provider = PluginStateProvider.of(context);
    return RepaintBoundary(
      child: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: provider.keyboardHeightNotifier,
            builder: (context, keyboardHeight, child) {
              return GestureDetector(
                onTapUp: widget.onTapUp,
                onDoubleTap: () {},
                onPanStart: keyboardHeight == 0.0 ? null : (_) {},
                behavior: .opaque,
                child: Container(color: Colors.transparent, width: .infinity, height: .infinity),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: provider.textInsertionPointNotifier,
            builder: (context, value, child) {
              return Positioned(
                top: value.dy,
                left: value.dx,
                child: GestureDetector(
                  behavior: .opaque,
                  onPanUpdate: (details) {
                    provider.textInsertionPointNotifier.moveByDelta(details.delta);
                  },
                  onPanDown: (details) {
                    setState(() {
                      _decoration = InputDecoration(
                        isCollapsed: true,
                        border: const OutlineInputBorder(),
                        fillColor: provider.draggingTextFieldBackgroundColor.withValues(alpha: 0.2),
                        filled: true,
                      );
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _decoration = const InputDecoration(isCollapsed: true, border: .none);
                    });
                  },
                  onPanCancel: () {
                    setState(() {
                      _decoration = const InputDecoration(isCollapsed: true, border: .none);
                    });
                  },
                  child: ValueListenableBuilder4(
                    first: provider.annotationColourNotifier,
                    second: provider.fontSizeNotifier,
                    third: provider.fontFamilyNotifier,
                    fourth: provider.textFocusNodeNotifier,
                    builder:
                        (context, annotationColour, fontSize, fontFamily, textFocusNode, child) {
                          return IntrinsicWidth(
                            child: Focus(
                              child: TextField(
                                decoration: _decoration,
                                autocorrect: false,
                                enableSuggestions: false,
                                cursorColor: annotationColour,
                                style: TextStyle(
                                  height: 1.15,
                                  letterSpacing: 0.0,
                                  fontSize: fontSize * widget.scale,
                                  fontFamily: fontFamily,
                                  fontWeight: .w600,
                                  color: annotationColour,
                                ),
                                controller: widget.textFieldController,
                                focusNode: textFocusNode,
                                contextMenuBuilder: null,
                                enableInteractiveSelection: false,
                                maxLines: 1,
                                onChanged: (text) {
                                  if (text.length == 1) {
                                    widget.onFirstCharacterEntry();
                                  }
                                },
                                onTapOutside: (_) {
                                  provider.textFieldShowingNotifier.value = false;
                                  widget.onTapOutside(widget.textFieldController.text);
                                },
                              ),
                              onFocusChange: (hasFocus) {
                                if (!hasFocus) {
                                  provider.textFieldShowingNotifier.value = false;
                                  widget.onTapOutside(widget.textFieldController.text);
                                }
                              },
                            ),
                          );
                        },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ValueListenableBuilder4<A, B, C, D> extends StatelessWidget {
  const ValueListenableBuilder4({
    super.key,
    required this.first,
    required this.second,
    required this.third,
    required this.fourth,
    required this.builder,
    this.child,
  });

  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final ValueListenable<C> third;
  final ValueListenable<D> fourth;
  final Widget? child;
  final Widget Function(BuildContext context, A a, B b, C c, D d, Widget? child) builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<A>(
    valueListenable: first,
    builder: (_, a, _) {
      return ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (context, b, _) {
          return ValueListenableBuilder<C>(
            valueListenable: third,
            builder: (context, c, _) {
              return ValueListenableBuilder<D>(
                valueListenable: fourth,
                builder: (context, d, _) {
                  return builder(context, a, b, c, d, child);
                },
              );
            },
          );
        },
      );
    },
  );
}
