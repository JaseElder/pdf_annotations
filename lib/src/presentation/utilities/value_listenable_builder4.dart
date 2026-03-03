import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
