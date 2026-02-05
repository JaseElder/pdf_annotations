import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

import 'annotation_base.dart';

class LineAnnotation extends Equatable implements AnnotationBase {
  @override
  final String id;
  final List<Offset> line;
  final Color colour;
  final double width;
  @override
  final bool isActive;

  LineAnnotation(List<Offset> line, this.colour, this.width, [this.isActive = true, String? id])
    : line = List.unmodifiable(line),
      id = id ?? nanoid(4);

  LineAnnotation copyWith({
    String? id,
    List<Offset>? line,
    Color? colour,
    double? width,
    bool? isActive,
  }) {
    return LineAnnotation(
      line ?? this.line,
      colour ?? this.colour,
      width ?? this.width,
      isActive ?? this.isActive,
      id ?? this.id,
    );
  }

  @override
  Offset get primaryCoordinate => line.first;

  Map<String, dynamic> toJson() {
    List<Offset> points = line;
    List jsonLine = [];
    for (Offset pair in points) {
      jsonLine.add([pair.dx, pair.dy]);
    }
    return {
      'id': id,
      'line': jsonLine,
      'colour': colour.toARGB32(),
      'width': width,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toJsonWithTransform(Offset transform) {
    final transformedLine = line.map((offset) => offset - transform).toList();
    final tempLine = copyWith(line: transformedLine);
    return tempLine.toJson();
  }

  factory LineAnnotation.fromJson(Map<String, dynamic> json) {
    final lineCoordinates = json['line'] as List<dynamic>;

    return LineAnnotation(
      lineCoordinates.map((item) => Offset(item[0].toDouble(), item[1].toDouble())).toList(),
      Color(json['colour'] as int),
      json['width'] as double,
      json['is_active'] as bool,
      json['id'] as String,
    );
  }

  @override
  String toString() =>
      'LineAnnotation{id: $id, line: $line, colour: $colour, width: $width, isActive: $isActive}';

  @override
  List<Object?> get props => [id, line, colour, width, isActive];
}
