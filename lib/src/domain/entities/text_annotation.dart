import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

import 'annotation_base.dart';

class TextAnnotation implements AnnotationBase {
  @override
  final String id;
  String text;
  late String fontFamily;
  double pdfFontSize;
  double renderedFontSize;
  late Offset coordinate;
  late Offset originalCoordinate;
  late Color colour;
  @override
  bool isActive;

  TextAnnotation(
    this.text,
    this.fontFamily,
    this.pdfFontSize,
    this.renderedFontSize,
    this.coordinate,
    this.colour, [
    this.isActive = true,
    String? id,
  ]) : id = id ?? nanoid(4),
       originalCoordinate = coordinate;

  TextAnnotation.clone(TextAnnotation other)
    : this(
        other.text,
        other.fontFamily,
        other.pdfFontSize,
        other.renderedFontSize,
        other.coordinate,
        other.colour,
        other.isActive,
        other.id,
      );

  TextAnnotation copyWith({
    String? id,
    String? text,
    String? fontFamily,
    double? pdfFontSize,
    double? renderedFontSize,
    Offset? coordinate,
    Color? colour,
    bool? isActive,
  }) {
    return TextAnnotation(
      text ?? this.text,
      fontFamily ?? this.fontFamily,
      pdfFontSize ?? this.pdfFontSize,
      renderedFontSize ?? this.renderedFontSize,
      coordinate ?? this.coordinate,
      colour ?? this.colour,
      isActive ?? this.isActive,
      id ?? this.id,
    );
  }

  @override
  Offset get primaryCoordinate => coordinate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'font_family': fontFamily,
    'pdf_font_size': pdfFontSize,
    'rendered_font_size': renderedFontSize,
    'coordinate': [coordinate.dx, coordinate.dy],
    'colour': colour.toARGB32(),
    'is_active': isActive,
  };

  Map<String, dynamic> toJsonWithTransform(Offset transform) {
    TextAnnotation tempText = TextAnnotation.clone(this);
    tempText.coordinate = coordinate - transform;
    return tempText.toJson();
  }

  factory TextAnnotation.fromJson(Map<String, dynamic> json) {
    final coordinatePoints = json['coordinate'] as List<dynamic>;
    return TextAnnotation(
      json['text'] as String,
      json['font_family'] as String? ?? json['font_name'] as String,
      json['pdf_font_size'] as double,
      json['rendered_font_size'] as double,
      Offset(coordinatePoints[0] as double, coordinatePoints[1] as double),
      Color(json['colour'] as int),
      json['is_active'] as bool,
      json['id'] as String,
    );
  }

  @override
  String toString() {
    return 'TextAnnotation{id: $id, text: $text, fontFamily: $fontFamily, pdfFontSize: $pdfFontSize, '
        'renderedFontSize $renderedFontSize, coordinate: $coordinate, originalCoordinate: $originalCoordinate, '
        'colour: $colour, isActive: $isActive}';
  }
}
