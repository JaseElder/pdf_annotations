import 'dart:ui';

import 'package:flutter/foundation.dart';

class TextInsertionPointNotifier extends ValueNotifier<Offset> {
  TextInsertionPointNotifier(super.value);

  void moveByDelta(Offset delta) {
    value += delta;
  }

  void setAbsolute(Offset point) {
    value = point;
  }
}
